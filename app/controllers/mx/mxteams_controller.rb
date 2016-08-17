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
		team.mxteam_set_name = name
		@mxteam = team
		if MXTeamHelper.add_team team			
			redirect_to mxteam_path(name), notice: 'mxteam was successfully created.'
		else
			render action: "new"
		end
	end

	def show
		mxteam
		@projects = @mxteam.mxteam_projects
	end

	def update
		mxteam
		del_project_id = params[:delProjectId]
		if del_project_id
		else
		end
	end

	def mxteam
		name = params[:id]
		team = MXTeamHelper.find_by_name name
		@mxteam = team ? team : MXTeamHelper.init
	end
end
