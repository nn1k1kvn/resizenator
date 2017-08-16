#!/bin/bash
# Copyright (c) 2017 Mikhail Shilov
# V 0.1.0.
# Исходники на Гитхабе https://goo.gl/RYo3ph
# Обратная связь: https://fb.com/miksha.happy
# Описание: ресайз всех картинок в папке, где находится скрипт 
# Параметры: res.sh  [ширина] [высота] 

# Внимание! зависимость от imagemagick 
# Install imagemagick on Ubuntu
# sudo add-apt-repository main
# sudo add-apt-repository universe
# sudo apt-get update
# sudo apt-get install imagemagick
# Install imagemagick on Mac OSX
# ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
# brew install imagemagick

# доработки:
# продизинфенцировать названия файлов и усеченые файлы.


PKG_OK=$(dpkg-query -W --showformat='${Status}\n' imagemagick | grep "install ok installed")
#echo Проверка на наличие пакета imagemagick: $PKG_OK
if [ "" == "$PKG_OK" ]; then
	echo "Ошибка. Требуется установить пакет imagemagick"  >&2; exit 1
:	' # если с установкой 
	echo -e "Не установлен пакет imagemagick."
	read -p "Установить? [Д/н] [Y/n] " -n 1 -r
	echo    # перевод строки
	if [[ $REPLY =~ ^[YyДд]$ ]]; then
  		sudo add-apt-repository -y main
  		sudo add-apt-repository -y universe
  		sudo apt-get -y update
  		sudo apt-get -y install imagemagick
  	else
  		exit 0
  	fi
	'
fi
# размеры по умолчанию 

DW=800
DH=600

PATTERN_IMG=".*\.(PNG|JPG|JPEG|BMP)" #конвертироваться будут только файлы, соответствующие заданному шаблону.

# получаем параметры и передаем им значения по умолчанию если параметры не были переданы
w=${1:-$DW}
h=${2:-$DH}

# получаем текущую  дирректорию с учетом символических ссылок
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "Текущая дирректория: $DIR"  

#

get_sizes ()  # запрашивает размеры
{   
    #printf "\033c"
	echo  'Введите, пожалуйста, нужные вам размеры картинок:'
	read -p "Ширина: " w
	read -p "Высота: " h
	w=${w:-$DW}
	h=${h:-$DH}
	check_wh_valid

}


check_wh_valid () # проверяет размеры на валидность
{
	
# проверяем размеры на валидность. Должно быть целое положительное число.
re='^0*([1-9][0-9]*)$' #'^[0-9]+$'
if ! [[ $w =~ $re && $h =~ $re ]] ; then
   echo "Размер должен быть указан как положительное целое число. Попробуйте еще раз." 
   get_sizes 
fi
}


# если параметры нам не передали

if ! [[ -n "${1}"  &&  -n "${2}" ]]  ; then 
	get_sizes   # запрашиваем размеры
else 
	check_wh_valid
fi



cat  << EOF
Вы указали
Ширину: $w
Высоту: $h
EOF

read -p "Всё верно? [Д/н] [Y/n] " -n 1 -r
echo    # перевод строки
if [[ $REPLY =~ ^[YyДд]$ ]]
then
	for i in "$DIR"/*; do
    	[ -f "$i" ] || continue 						 # переход в начало цикла если не файл
       	filename="${i##*/}" 				   			 # получаем название файла из full path
    	if  [[ ${filename^^}  =~ $PATTERN_IMG ]]         # конвертируем $filename в верхний регистр и сравниваем с regex 
    	then 
    	    let cnt=cnt+1                                # счетчик сконвертированных файлов
    		echo $filename 
    		#"2017-03-20 15.19.11 копияx.jpg JPEG 600x400 600x400+0+0 8-bit DirectClass 55.2KB 0.000u 0:00.000"
    		SIZE=$(identify "$filename" | grep -oP "(?<=\s)(\d+x\d+)(?=\s)") # вытаскиваем размер 
	 		SIZEX=$(echo $SIZE | cut -f 1 -d 'x')        # ширина
    		SIZEY=$(echo $SIZE | cut -f 2 -d 'x')        # высота
            # конвертируем
    		if [[ $SIZEX -ge $SIZEY ]]  # >=
			then
		  		convert -size ${w}x${h} "${filename}" -resize ${w}x${h} "${filename}"
			else
  		  		convert -size ${h}x${w} "${filename}" -resize ${h}x${w} "{$filename}"
			fi
		fi 
	done
	
	if [[ cnt -eq 0 ]] # =
	then
		echo -e "Ошибка: В текущей дирректории не найдены файлы с изображениями." >&2; exit 1
	else
		echo -n "Конвертация завершена. "
		echo -e "Обработано $cnt файлов."
	fi
fi