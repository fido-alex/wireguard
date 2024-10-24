#!/bin/bash
codename=`lsb_release -c | grep "Codename" | awk -F" " '{print $2}'`

function basic_image {
  ! test -d ~/docker && mkdir ~/docker
  cd ~/docker
  sudo debootstrap bookworm bookworm > /dev/null
  sudo tar -C $codename -c . | docker import - $codename
  docker images
  sleep 3
}

function delete_image {
  remove_image_path=`docker images | grep "$1" | awk -F" " '{print $3}'`
  docker rmi "$remove_image_path"
  docker images
  sudo rm -rf ~/docker/"$1"/
  sleep 7
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
  echo 'CMD ["bash"]' >> Dockerfile
  docker build -t $1 .
  docker images
  docker run -it --rm --network=host --name="$1" "$1"
  sleep 7
}

while [ "$wireguard" != "q" ] | [ "$wireguard" != "Q" ]
#clear
do
  echo "[q] quit"
  echo "[b] base install"
  echo "[br] base remove"
  echo "[w] wireguard install"
  echo "[wr] wireguard remove"
  echo "[ws] wireguard run bash"

  read wireguard

  case "$wireguard" in

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
    echo "wireguard install"
    # Создаём образ wirwguard
    image_creation wireguard
    ;;

    "WR" | "wr" )
    echo "wireguard remove"
    # Удаляем образ wireguard
    delete_image wireguard
    ;;

    "WS" | "ws" )
    echo "wireguard run bash"
    # Запускаем контейнер wireguard и подключаемся к коммандному интерпретатору
    #docker stop wireguard
    docker run -it --rm --network=host --name=wireguard wireguard
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
