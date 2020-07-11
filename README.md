# docker-deeplearning
Docker config for deep learning platform which includes mutiple machines.
Here is the .sh file for creating such platform
# Prerequisities
1. Install Nvidia-docker in each machine and latest nvidia driver(downward compatible)   
2. Install NFS, and share the same folder in each machine manually(not implemented in .sh file)

# Features
1. Each user has isolated deep-learning environment 
2. Any operations(such as apt-get.etc) will be synchronized within each machine without repeat and annoying configuration 
3. Users can access each machine using ssh freely
4. All the data are transformed through NFS for data(datasets and the config files) sharing

