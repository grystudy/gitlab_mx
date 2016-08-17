class Mx::MxteamsController < Mx::ApplicationController
	def new
		@mxteam = MXTeamHelper.new_mxteam 'new_mxteam'
	end

	def create
		name = params[:name]
		unless name && !name.empty?
			render action: "new" 
			return
		end
		team = MXTeamHelper.new_mxteam name
		@mxteam = team
		if MXTeamHelper.get_depot.save team			
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
		importing = params[:importing]
		if importing
			project_id = params[:source_project_id]
			if project_id
				case importing
				when "0"
					if @mxteam.mxteam_process_project_ids([project_id.to_i],true) && save
						redirect_to mxteam_path(@mxteam.mxteam_name), notice: 'project was successfully added.'
						return
					end
				when "1"
				else
				end
			end
		end

		del_project_id = params[:delProjectId]
		if del_project_id
			if @mxteam.mxteam_process_project_ids([del_project_id.to_i],false) && save
				redirect_to mxteam_path(@mxteam.mxteam_name), notice: 'project was successfully deleted.'
				return
			end
		end

		redirect_to mxteam_path(@mxteam.mxteam_name), notice: 'failed.'
	end

	def select_project
		mxteam
		@importing = 0
	end

	def import_users
		mxteam
		@importing = 1
		render action: "select_project"
	end

	def mxteam
		name = params[:id]
		team = MXTeamHelper.get_depot.find_by_name name
		@mxteam = team ? team : MXTeamHelper.new_mxteam("not found")
	end

	def save
		MXTeamHelper.get_depot.save @mxteam
	end
end
