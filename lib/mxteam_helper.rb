class MXTeamDepot
	Postfix = ".team"

	def initialize
		@file_lock = Mutex.new
	end

	def find_by_name name_
		data = get_names
		return nil unless data
		teams = data.select{|i_| i_.length > 0 && i_ == name_}
		return nil unless teams && teams.length > 0
		load teams[0]
	end

	def get_names
		dir = get_dir_name
		return [] unless File.directory? dir
		res = []
		@file_lock.synchronize{
			Dir.entries(dir).each do |f_name|
				if File.file? File.join(dir,f_name)
					ext = File.extname f_name
					res << f_name if ext && ext.include?(Postfix)
				end
			end
		}
		res
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
			data = MXTeamHelper.read file_name if File.exist? file_name
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
end

class Array
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
	
	def mxteam_projects
		ids = mxteam_sub_item_ids 1 
		return [] unless ids && ids.length > 0
		res = []
		ids.each do |item|
			begin
				project = Project.find(item)
				res << project if project
			rescue Exception => e
				next
			end
		end
		res
	end

	def mxteam_del_project_ids items_
		return false unless items_ && items_.length > 0
		projects = mxteam_sub_item_ids 1
		return mxteam_set_sub_item_ids MXTeamHelper.diff projects,items_
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