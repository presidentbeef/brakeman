require 'brakeman/checks/base_check'
require 'set'

#Checks for mass assignments to models.
#
#See http://guides.rubyonrails.org/security.html#mass-assignment for details
class Brakeman::CheckMassAssignment < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds instances of mass assignment"

  def run_check
    return if mass_assign_disabled?

    models = []
    tracker.models.each do |name, m|
      if unprotected_model? m
        models << name
      end
    end

    return if models.empty?


    Brakeman.debug "Finding possible mass assignment calls on #{models.length} models"
    calls = tracker.find_call :chained => true, :targets => models, :methods => [:new,
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

    Brakeman.debug "Processing possible mass assignment calls"
    calls.each do |result|
      process_result result
    end
  end

  #All results should be Model.new(...) or Model.attributes=() calls
  def process_result res
    call = res[:call]

    check = check_call call

    if check and not call.original_line and not duplicate? res
      add_result res

      model = tracker.models[res[:chain].first]

      attr_protected = (model and model[:options][:attr_protected])

      if attr_protected and tracker.options[:ignore_attr_protected]
        return
      elsif input = include_user_input?(call.arglist)
        first_arg = call.first_arg

        if call? first_arg and (first_arg.method == :slice or first_arg.method == :only)
          return
        elsif not node_type? first_arg, :hash
          if attr_protected
            confidence = CONFIDENCE[:med]
          else
            confidence = CONFIDENCE[:high]
          end
          user_input = input.match
        else
          confidence = CONFIDENCE[:low]
          user_input = input.match
        end
      else
        confidence = CONFIDENCE[:low]
        user_input = nil
      end
      
      warn :result => res, 
        :warning_type => "Mass Assignment", 
        :warning_code => :mass_assign_call,
        :message => "Unprotected mass assignment",
        :code => call, 
        :user_input => user_input,
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
end
