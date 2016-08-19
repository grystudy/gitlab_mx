class MXTeamDepot
	Postfix = ".team"

	def initialize
		@file_lock = Mutex.new
	end

	def find_by_name name_
		return nil unless name_
		data = get_names
		return nil unless data
		teams = data.select{|i_| i_.length > 0 && i_ == name_}
		return nil unless teams && teams.length > 0
		load teams[0] + Postfix
	end

	def get_names
		dir = get_dir_name
		return [] unless File.directory? dir
		res = []
		@file_lock.synchronize{
			Dir.entries(dir).each do |f_name|
				if File.file? File.join(dir,f_name)
					ext = File.extname f_name
					res << File.basename(f_name,Postfix) if ext && ext.include?(Postfix)
				end
			end
		}
		res.sort
	end

	def get_dir_name
		"#{Rails.root}/public/mxteam_data"
	end

	def save data
		return false unless data
		dir = get_dir_name
		@file_lock.synchronize{
			MXTeamHelper.ensure_dir dir
			MXTeamHelper.write File.join(dir,data.mxteam_name + Postfix),[data]
		}
		true
	end

	def load file_name
		dir = get_dir_name
		file_name = File.join dir,file_name
		data = nil
		@file_lock.synchronize{
			data = MXTeamHelper.read file_name if File.exists? file_name
		}
		return nil unless data && data.length > 0
		data.each do |item_|
			if item_&&item_.length < 3 
				(0..(3-item_.length)).each do
					item_ << ""
				end
			end
		end
		data[0]
	end

	def load_other_teams except_name
		names = get_names
		return [] if names.empty?
		res = []
		names.each do |name|
			next if except_name && (name == except_name)
			data = load(name + Postfix)
			res << data if data
		end
		res
	end

	def delete team_name
		return true unless team_name
		file_name = File.join(get_dir_name,team_name + Postfix)
		@file_lock.synchronize{
			return true unless File.exists? file_name
			File.delete file_name
	  }
		true
	end

	def establish_rel pro_ids_,user_ids_
		return true unless pro_ids_ && !pro_ids_.empty?
		return true unless user_ids_ && !user_ids_.empty?
		pro_ids_.each do |pro_id|
			project = nil
			begin
				project = Project.find pro_id
			rescue Exception => e
				next
			end
			next unless project
			pro_user_ids = project.users_projects.pluck(:user_id)
			pro_user_ids = [] unless pro_user_ids
			mem_to_add = []
			user_ids_.each do |mem_id|
				next if pro_user_ids.include? mem_id
				mem_to_add << mem_id
			end
			project.team.add_users_ids(mem_to_add,:developer) unless mem_to_add.empty?
		end
		true
	end

	def break_rel cur_team_name_,pro_ids_,user_ids_
		return true unless pro_ids_ && !pro_ids_.empty?
		return true unless user_ids_ && !user_ids_.empty?
		other_teams = load_other_teams cur_team_name_
		pro_ids_.each do |pro_id|
			project = nil
			begin
				project = Project.find pro_id
			rescue Exception => e
				next
			end
			next unless project
			user_ids_.each do |mem_id|
				next if other_teams.index{|i_| i_.mxteam_project_ids.include?(pro_id) && i_.mxteam_member_ids.include?(mem_id)}
				relation = project.users_projects.find_by(user_id: mem_id) 
				relation.destroy if relation && relation.project_access < Gitlab::Access::MASTER
			end
		end
		true
	end
end

class Array
	def mxteam_destroy
		name = self[0]
		MXTeamHelper.get_depot.delete name
	end

	def mxteam_name
		return "" unless length > 0
		self[0]
	end

	def mxteam_set_name name_
		return false unless length > 0
		return false unless name_ && name_.length > 0
		self[0] = name_
		true
	end

	def mxteam_sub_item_ids index_
		return [] unless length > index_
		str = self[index_]
		return [] unless str && str.length > 0
		ids = str.split ';'
		return [] unless ids && ids.length > 0
		ids.map { |e| e.to_i }
	end

	def mxteam_set_sub_item_ids data_ , index_
		return false unless length > index_
		return false unless data_ 
		self[index_] = data_.join ';'
		true
	end
	
	def mxteam_project_ids
		mxteam_sub_item_ids 1
	end

	def mxteam_projects
		ids = mxteam_project_ids
		return [] unless ids && ids.length > 0	
		begin
			return Project.where(id: ids).all
		rescue Exception => e
			return []
		end		
	end

	def mxteam_member_ids
		mxteam_sub_item_ids 2 
	end

	def mxteam_members
		ids = mxteam_member_ids
		return [] unless ids && ids.length > 0	
		begin
			return User.where(id: ids).all
		rescue Exception => e
			return []
		end		
	end

	def mxteam_import_members_form_project_id id
		return false unless id
		project = Project.find_by(id: id)
		return false unless project
		user_ids = project.users_projects.pluck(:user_id)
		return false unless user_ids
		return true if user_ids.length == 0
		mxteam_process_member_ids user_ids,true
	end

	def mxteam_process_project_ids items_,add_or_diff
		members = mxteam_member_ids 
		depot = MXTeamHelper.get_depot
		return false unless (add_or_diff ? depot.establish_rel(items_,members) : depot.break_rel(mxteam_name,items_,members))
		mxteam_process_ids items_,add_or_diff,1
	end

	def mxteam_process_member_ids items_,add_or_diff
		projects = mxteam_project_ids
		depot = MXTeamHelper.get_depot
		return false unless (add_or_diff ? depot.establish_rel(projects,items_) : depot.break_rel(mxteam_name,projects,items_))
		mxteam_process_ids items_,add_or_diff,2
	end

	def mxteam_process_ids items_,add_or_diff,index_
		return false unless items_ && items_.length > 0
		projects = mxteam_sub_item_ids index_
		res = add_or_diff ? (MXTeamHelper.union projects,items_) : (MXTeamHelper.diff projects,items_)
		mxteam_set_sub_item_ids(res,index_) && MXTeamHelper.get_depot.save(self)
	end
end

class MXTeamHelper
	@depot 
	
	Tab = "\t"
	New_Line = "\n"

	class << self
		def get_depot
			depot = @depot
			unless depot
				depot = MXTeamDepot.new
				@depot = depot
			end
			depot
		end

		def new_mxteam name
			[name ? name : "","",""]
		end

		def ensure_dir(dirName_)
			Dir.mkdir dirName_ unless File.directory? dirName_
		end

		def read file_name_
			return [] unless file_name_
			lines = []
			File.open(file_name_,"r",:encoding => 'UTF-8') do |io|
				io.each do |line|
					array = line.chomp.split Tab
					lines << array
				end
			end
			lines
		end

		def write(fileName, data)
			return false if !data
			File.open(fileName, "w", :encoding => 'UTF-8') do |io|
				data.each_with_index do |line,i|
					line_str = line.join(Tab).gsub(/\n/,"<br>")
					io.write line_str
					if i != data.count - 1            
						io.write(New_Line)
					end
				end
			end
			true
		end

		def union array_1,array_2
			return [] if !array_1 && !array_2
			return array_1 if !array_2
			return array_2 if !array_1
			(array_1 + array_2).uniq
		end

		def diff array_1,array_2
			return [] if !array_1 
			return array_1 if !array_2
			(array_1 - array_2).uniq
		end
	end
end