require 'brakeman/checks/base_check'
require 'set'

#Checks for mass assignments to models.
#
#See http://guides.rubyonrails.org/security.html#mass-assignment for details
class Brakeman::CheckMassAssignment < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds instances of mass assignment"

  def initialize(*)
    super
    @mass_assign_calls = nil
  end

  def run_check
    check_mass_assignment
    check_permit!
  end

  def find_mass_assign_calls
    return @mass_assign_calls if @mass_assign_calls

    models = []
    tracker.models.each do |name, m|
      if m.is_a? Hash
        p m
      end
      if m.unprotected_model?
        models << name
      end
    end

    return [] if models.empty?

    Brakeman.debug "Finding possible mass assignment calls on #{models.length} models"
    @mass_assign_calls = tracker.find_call :chained => true, :targets => models, :methods => [:new,
      :attributes=,
      :update_attributes,
      :update_attributes!,
      :create,
      :create!,
      :build,
      :first_or_create,
      :first_or_create!,
      :first_or_initialize!,
      :assign_attributes,
      :update
    ]
  end

  def check_mass_assignment
    return if mass_assign_disabled?

    Brakeman.debug "Processing possible mass assignment calls"
    find_mass_assign_calls.each do |result|
      process_result result
    end
  end

  #All results should be Model.new(...) or Model.attributes=() calls
  def process_result res
    call = res[:call]

    check = check_call call

    if check and original? res

      model = tracker.models[res[:chain].first]

      attr_protected = (model and model.attr_protected)

      if attr_protected and tracker.options[:ignore_attr_protected]
        return
      elsif input = include_user_input?(call.arglist)
        first_arg = call.first_arg

        if call? first_arg and (first_arg.method == :slice or first_arg.method == :only)
          return
        elsif not node_type? first_arg, :hash
          if attr_protected
            confidence = :medium
          else
            confidence = :high
          end
        else
          return
        end
      elsif node_type? call.first_arg, :lit, :str
        return
      else
        confidence = :weak
        input = nil
      end

      warn :result => res,
        :warning_type => "Mass Assignment",
        :warning_code => :mass_assign_call,
        :message => "Unprotected mass assignment",
        :code => call,
        :user_input => input,
        :confidence => confidence
    end

    res
  end

  #Want to ignore calls to Model.new that have no arguments
  def check_call call
    process_call_args call

    if call.method == :update
      arg = call.second_arg
    else
      arg = call.first_arg
    end

    if arg.nil? #empty new()
      false
    elsif hash? arg and not include_user_input? arg
      false
    elsif all_literal_args? call
      false
    else
      true
    end
  end

  LITERALS = Set[:lit, :true, :false, :nil, :string]

  def all_literal_args? exp
    if call? exp
      exp.each_arg do |arg|
        return false unless literal? arg
      end

      true
    else
      exp.all? do |arg|
        literal? arg
      end
    end

  end

  def literal? exp
    if sexp? exp
      if exp.node_type == :hash
        all_literal_args? exp
      else
        LITERALS.include? exp.node_type
      end
    else
      true
    end
  end

  # Look for and warn about uses of Parameters#permit! for mass assignment
  def check_permit!
    tracker.find_call(:method => :permit!).each do |result|
      if params? result[:call].target and not result[:chain].include? :slice
        warn_on_permit! result
      end
    end
  end

  # Look for actual use of params in mass assignment to avoid
  # warning about uses of Parameters#permit! without any mass assignment
  # or when mass assignment is restricted by model instead.
  def subsequent_mass_assignment? result
    location = result[:location]
    line = result[:call].line
    find_mass_assign_calls.any? do |call|
      call[:location] == location and
      params? call[:call].first_arg and
      call[:call].line >= line
    end
  end

  def warn_on_permit! result
    return unless original? result

    confidence = if subsequent_mass_assignment? result
                   :high
                 else
                   :medium
                 end

    warn :result => result,
      :warning_type => "Mass Assignment",
      :warning_code => :mass_assign_permit!,
      :message => "Parameters should be whitelisted for mass assignment",
      :confidence => confidence
  end
end
