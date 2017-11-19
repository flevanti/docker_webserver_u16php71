docker rm webserver -f
docker build -t webserver .
docker create --name webserver -p 80:80 webserver 
docker start webserver
docker ps -a
docker exec -ti webserver bash
