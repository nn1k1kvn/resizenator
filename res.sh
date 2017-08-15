#!/bin/bash
# Copyright (c) 2017 Mikhail Shilov
# V 0.1.0.
# Исходники на Гитхабе https://goo.gl/RYo3ph
# Обратная связь: https://fb.com/miksha.happy
# Описание: ресайз всех картинок в папке, где находится скрипт 
# Параметры: res.sh  [ширина] [высота] 
# Внимание! может потребоваться imagemagick 
# Установка imagemagick в Ubuntu 
# sudo add-apt-repository main
# sudo add-apt-repository universe
# sudo apt-get update
# sudo apt-get install imagemagick

# размеры по умолчанию 
w=${1:-800}
h=${2:-600}

pattern="IMG_*.JPG" #конвертироваться будут только файлы, соответствующие заданному шаблону. Регистр учитывается. 

# цветовая  схема
RED='\031[0;31m'
GREEN='\032[0;32m'
NC='\033[0m' # No Color

# получаем текущую  дирректорию с учетом символических ссылок
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "Текущая дирректория: $DIR"  

# если параметры нам не передали

if ! [[ -n "${1}"  &&  -n "${2}" ]]  ; then 
    echo  'Введите, пожалуйста, нужные вам размеры картинок:'
	read -p "Ширина: " w
	read -p "Высота: " h
	w=${w:-800}
	h=${h:-600}
fi

# проверяем размеры на валидность. Должно быть целое положительное число.
re='[-+]?0*([1-9][0-9]*[02468]|[2468])$' #'^[0-9]+$'
if ! [[ $w =~ $re && $h =~ $re ]] ; then
   echo "Ошибка: Размер должен быть указан как положительное целое число. Попробуйте еще раз." >&2; exit 1
fi


cat  << EOF
Вы указали
Ширину: $w
Высоту: $h
EOF

read -p "Всё верно? " -n 1 -r
echo    # перевод строки
if [[ $REPLY =~ ^[YyДд]$ ]]
then
	for i in "$DIR"/*; do
    	[ -f "$i" ] || continue
     
        #просматриваем в папке только файлы
    	filename="${i##*/}"
    	if  [[ $filename  == $pattern ]]  # совпадающие с шаблоном

    	then 
    	    let cnt=cnt+1
    		echo "${i##*/}" 
    		SIZE=$(identify $filename | cut -f 3 -d ' ') 
    		SIZEX=$(echo $SIZE | cut -f 1 -d 'x')
    		SIZEY=$(echo $SIZE | cut -f 2 -d 'x') 
            # конвертируем
    		if (test $SIZEX -ge $SIZEY)
			then
		  		convert -size ${w}x${h} $filename -resize ${w}x${h} $filename
			else
  		  		convert -size ${h}x${w} $filename -resize ${h}x${w} $filename
			fi
		fi 
	done
	
	if [[ cnt -eq 0 ]]
	then
		echo -e "Ошибка: В текущей дирректории не найдены файлы, соответствующие указанному шаблону." >&2; exit 1
	else
		echo -e "${GREEN}Конвертация завершена.${NC}"
		echo -e "Обработано $cnt файлов."
	fi
fi