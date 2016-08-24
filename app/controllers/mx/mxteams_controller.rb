class Mx::MxteamsController < Mx::ApplicationController
	def new
		@mxteam = MXTeamHelper.new_mxteam 'new_mxteam'
	end

	def destroy
		mxteam
		if @mxteam.mxteam_destroy
			redirect_to root_path, notice: 'mxteam was successfully deleted.'
		else
			redirect_to mxteam_path(@mxteam.mxteam_name), notice: 'failed.'
		end
	end

	def create
		name = params[:name]
		unless name && name.length > 0
			redirect_to new_mxteam_path,notice: 'name is empty!'
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
		if !@mxteam.mxteam_can_manage(current_user)
			redirect_to root_path, notice: 'you can not manager this mxteam!'
			return
		end
		@projects = @mxteam.mxteam_projects
	end

	def edit
		mxteam
		if !@mxteam.mxteam_can_manage(current_user)
			redirect_to root_path, notice: 'you can not manager this mxteam!'
			return
		end
		b = is_setting_manager
		@members = b ? @mxteam.mxteam_managers : @mxteam.mxteam_members
		@setting_manager = b ? 1 : 0
	end

	def update
		mxteam
		importing = params[:importing]
		if importing
			project_id = params[:source_project_id]
			if project_id
				case importing
				when "0"
					if @mxteam.mxteam_process_project_ids(project_id.map { |e| e.to_i },true)
						redirect_to mxteam_path(@mxteam.mxteam_name), notice: 'project was successfully added.'
						return
					end
				when "1"
					if @mxteam.mxteam_import_members_form_project_id(project_id.to_i)
						redirect_to edit_mxteam_path(@mxteam.mxteam_name) ,notice: 'members was successfully imported.'
						return
					end
				else
				end
			end
		end

		del_project_id = params[:delProjectId]
		if del_project_id
			if @mxteam.mxteam_process_project_ids([del_project_id.to_i],false)
				redirect_to mxteam_path(@mxteam.mxteam_name), notice: 'project was successfully deleted.'
				return
			end
		else
			del_member_id = params[:delMemberId]
			if del_member_id 
				if is_setting_manager
					if @mxteam.mxteam_process_manager_ids([del_member_id.to_i],false)
						redirect_to edit_mxteam_path(@mxteam.mxteam_name)+"?setting_manager=1",notice: 'manager was successfully deleted.'
						return
					end
				elsif @mxteam.mxteam_process_member_ids([del_member_id.to_i],false)
					redirect_to edit_mxteam_path(@mxteam.mxteam_name),notice: 'member was successfully deleted.'
					return
				end
			else
				add_member = params[:addMember]
				user_ids = params[:user_ids]
				if add_member && user_ids
					if is_setting_manager
						if @mxteam.mxteam_process_manager_ids(user_ids.map { |e| e.to_i },true)
							redirect_to edit_mxteam_path(@mxteam.mxteam_name)+"?setting_manager=1",notice: 'manager(s) was successfully added.'
							return
						end
					elsif @mxteam.mxteam_process_member_ids(user_ids.map { |e| e.to_i },true)
						redirect_to edit_mxteam_path(@mxteam.mxteam_name),notice: 'member(s) was successfully added.'
						return
					end
				end
			end
		end

		redirect_to mxteam_path(@mxteam.mxteam_name), notice: 'failed.'
	end

	def select_user
		mxteam
		b = is_setting_manager
		@setting_manager = b ? 1 : 0
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

	def is_setting_manager
		str = params[:setting_manager] 
		return false unless str
		str == "1"
	end
end
