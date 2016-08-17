class Mx::MxteamsController < Mx::ApplicationController
	def new
		@mxteam = MXTeamHelper.init
	end

	def create
		name = params[:name]
		unless name && !name.empty?
			render action: "new" 
			return
		end
		team = MXTeamHelper.init
		team[0] = name
		if MXTeamHelper.add_team team			
			redirect_to mxteam_path(name), notice: 'mxteam was successfully created.'
		else
			render action: "new"
		end
	end

	def show
		# name = params[:id]
		# data = MXTeamHelper.get_data
	end
end
