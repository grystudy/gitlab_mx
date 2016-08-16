class MXTeamDepot
	def initialize
		@data = []
		@data_lock = Mutex.new
		ensure_data true
	end

	def add_team item_
		ensure_data false
		return nil unless item_
		@data_lock.synchronize{
			@data = [] unless @data
			@data << item_
		}
		MXTeamHelper.save @data
		@data
	end

	def get_data
		ensure_data false
		@data
	end

	def save
		ensure_data false
		MXTeamHelper.save @data
	end

	def ensure_data refresh_
		data = @data
		return if false &&!refresh_ && data && data.length >0 
		@data_lock.synchronize{
			@data = MXTeamHelper.load
		}
		data = @data
		if data && data.length >0 
			@data_lock.synchronize{
				data.each do |item_|
					if item_&&item_.length < 3 
						(0..(3-item_.length)).each do
							item_ << ""
						end
					end
				end
			}
			return
		end
		@data = []
		data = @data			
		new_item = ["text_auto_created_team",Project.take.id,User.take.id]
		data << new_item
		MXTeamHelper.save data
	end
end

class MXTeamHelper
	@depot 
	@file_lock = Mutex.new

	Tab = "\t"
	New_Line = "\n"

	class << self
		def get_data			
			get_depot.get_data
		end

		def add_team item_
			get_depot.add_team item_
		end

		def get_depot
			depot = @depot
			unless depot
				depot = MXTeamDepot.new
				@depot = depot
			end
			depot
		end

		def init
			["","",""]
		end

		def save data
			return unless data
			@file_lock.synchronize{
				ensure_dir get_dir_name
				write get_file_name,data
			}
		end

		def load
			data = nil
			@file_lock.synchronize{
				file_name = get_file_name				
				data = read file_name if File.exist? file_name
			}
			data
		end

		def get_file_name
			File.join get_dir_name,"mxteams.txt"
		end

		def get_dir_name
			"#{Rails.root}/public/mxteam_data"
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
	end
end