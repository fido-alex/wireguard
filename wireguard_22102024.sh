#!/bin/bash
codename=`lsb_release -c | grep "Codename" | awk -F" " '{print $2}'`

function basic_image {
  ! test -d ~/docker && mkdir ~/docker
  cd ~/docker
  sudo debootstrap bookworm bookworm > /dev/null
  sudo tar -C $codename -c . | docker import - $codename
  docker images
  #sleep 3
}

function delete_image {
  remove_image_path=`docker images | grep "$1" | awk -F" " '{print $3}'`
  docker rmi "$remove_image_path"
  docker images
  sudo rm -rf ~/docker/"$1"/
  #sleep 7
}

function image_creation {
  ! test -d ~/docker/"$1" && mkdir ~/docker/"$1"
  ! test -d ~/docker/"$1"/src && mkdir ~/docker/"$1"/src
  cp /etc/apt/sources.list ~/docker/"$1"/src
  cd ~/docker/"$1"
  echo "FROM $codename" > Dockerfile
  echo "WORKDIR /app" >> Dockerfile
  echo "COPY ./src ./" >> Dockerfile
  echo "RUN mv sources.list /etc/apt/sources.list" >> Dockerfile
  echo "RUN apt update -y" >> Dockerfile
  echo "RUN apt upgrade -y" >> Dockerfile
  echo "RUN apt install -y wireguard" >> Dockerfile
  echo "RUN cd /etc/wireguard/" >> Dockerfile
  echo "RUN wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey" >> Dockerfile
  echo 'RUN privatekey=`cat /etc/wireguard/privatekey`' >> Dockerfile
  echo 'RUN echo '[Interface]' > wg0.conf' >> Dockerfile
  echo 'RUN echo "PrivateKey = $privatekey" >> wg0.conf' >> Dockerfile
  echo 'RUN echo "Address = 10.0.10.1/24" >> wg0.conf' >> Dockerfile
  echo 'RUN echo "ListenPort = 51831" >> wg0.conf' >> Dockerfile
  echo 'RUN echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE" >> wg0.conf' >> Dockerfile
  echo 'RUN echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eno1 -j MASQUERADE" >> wg0.conf' >> Dockerfile
  echo 'RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf' >> Dockerfile
  echo 'RUN systemctl enable wg-quick@wg0.service' >> Dockerfile
  echo 'CMD ["bash"]' >> Dockerfile
  docker build -t $1 .
  #docker images
  #docker run -it --rm --network=host --name="$1" "$1"
  #sleep 7
}

while [ "$main" != "q" ] | [ "$main" != "Q" ]
#clear
do
  echo "[q] quit"
  echo "[b] base install"
  echo "[br] base remove"
  echo "[w] wireguard"
  echo "[p] running containers"

  read main

  case "$main" in

    "B" | "b" )
    echo "base install"
    # Создаём папку docker и в ней создаём  базовый образ Debian
    basic_image
    ;;

    "BR" | "br" )
    # Удаляем базовый образ
    delete_image "$codename"
    ;;

    "W" | "w" )
    clear
    echo "[i] wireguard install docker image"
    echo "[r] wireguard remove"
    echo "[b] wireguard run bash"
    echo "[s] wireguard start"
    echo "[t] wireguard stop"
    echo "[q] return to main menu"

    read wireguard

    case "$wireguard" in
      
      "I" | "i" )
      echo "wireguard install docker image"
      # Создаём образ wirwguard
      image_creation wireguard
      ;;

      "R" | "r" )
      echo "wireguard remove"
      # Удаляем образ wireguard
      delete_image wireguard
      ;;

      "B" | "b" )
      echo "wireguard run bash"
      # Запускаем контейнер wireguard и подключаемся к коммандному интерпретатору
      #docker stop wireguard
      #docker run -it --rm --network=host --name=wireguard wireguard
      docker exec -it wireguard bash
      ;;

      "S" | "s" )
      echo "wireguard start"
      # Запускаем контейнер wireguard и подключаемся к коммандному интерпретатору
      #docker stop wireguard
      docker run -d -it --rm --network=host --name=wireguard wireguard
      #docker run -d -it --network=host --name=wireguard wireguard
      ;;

      "T" | "t" )
      echo "wireguard stop"
      # Запускаем контейнер wireguard и подключаемся к коммандному интерпретатору
      docker stop wireguard
      ;;

      "Q" | "q" )
      echo "return to main menu"
      sleep 1
      ;;

      * )
      echo "Нажмите правильную кнопку"
      sleep 1 
      ;;
    esac
    ;;

    "P" | "p" )
    echo "running containers"
    # Запущенные контейнеры
    docker ps
    ;;

    "Q" | "q" )
    echo "exit"
    #sleep 1
    exit 0
    ;;

    * )
    echo "Нажмите правильную кнопку"
    sleep 1 
    ;;
  esac

done

exit 0
