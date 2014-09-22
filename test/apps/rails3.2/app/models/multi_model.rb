module MultiModel
  class Model1 < ActiveRecord::Base

  	def model_exec
  	  system params[:user_input]
  	end

  end

  class Model2 < ActiveRecord::Base

  	def model_exec
  	  system params[:user_input2]
  	end

  end
end
