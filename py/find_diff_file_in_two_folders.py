# The script is used to identify file names appearing in a folder but not in the other when comparing two folders
import os

def diff_file_in_two_folders(folder_1, folder_2):
	file_folder_1 = os.listdir(folder_1)
	file_folder_2 = os.listdir(folder_2)
	# obtain differences
	diff_folder_1 = list(set(file_folder_1) - set(file_folder_2))
	diff_folder_2 = list(set(file_folder_2) - set(file_folder_1))
	# identify files and folders
	diff_file_folder_1 = [file for file in diff_folder_1 if not os.path.isdir(folder_1 + '/' + file)]
	diff_file_folder_2 = [file for file in diff_folder_2 if not os.path.isdir(folder_2 + '/' + file)]
	for name_file in diff_file_folder_1:
		print(folder_1 + '/' + name_file)
	for name_file in diff_file_folder_2:
		print(folder_2 + '/' + name_file)
	diff_folder_folder_1 = [file for file in diff_folder_1 if os.path.isdir(folder_1 + '/' + file)]
	diff_folder_folder_2 = [file for file in diff_folder_2 if os.path.isdir(folder_2 + '/' + file)]
	for name_folder in diff_folder_folder_1:
		print(folder_1 + '/' + name_folder + '/')
	for name_folder in diff_folder_folder_2:
		print(folder_2 + '/' + name_folder + '/')
	intersect_file = list(set(file_folder_1) & set(file_folder_2))
	intersect_folder = [file for file in intersect_file if os.path.isdir(folder_1 + '/' + file) and os.path.isdir(folder_2 + '/' + file)]
	for folder in intersect_folder:
		diff_file_in_two_folders(folder_1 + '/' + folder, folder_2 + '/' + folder)

# path_1 = '/Volumes/W-QC/Pictures/Photos/Shenzhen/20180520'
# path_2 = '/Volumes/W-QC-SSD/Photos/Shenzhen/20180520'
exit_flag = False
while not exit_flag:
	print("Input the first folder (Enter 'exit' to exit):")
	path_1 = input()
	if path_1 == 'exit':
		exit_flag = True
		exit()
	print("Input the second folder (Enter 'exit' to exit):")
	path_2 = input()
	if path_2 == 'exit':
		exit_flag = True
		exit()
	print("Unique files (those ending with '/' are unique folders):")
	diff_file_in_two_folders(path_1, path_2)
