#!/bin/bash
# Copyright (c) 2017 Mikhail Shilov
# V 0.1.0.
# Github: 	https://goo.gl/RYo3ph
# Feedback: https://fb.com/miksha.happy
# Description: change resize pictures in directory  
# res.sh  [width] [height] 
# OS: Ubuntu  14.04
# Dependent packages: imagemagick 
# Install imagemagick on Ubuntu
# sudo add-apt-repository main
# sudo add-apt-repository universe
# sudo apt-get update
# sudo apt-get install imagemagick
 

# Необходимые доработки:
# продизинфенцировать названия файлов и добавить логирование списка поврежденных файлов
# Портировать под Mac OSX 

#Проверка на наличие пакета imagemagick
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' imagemagick | grep "install ok installed")
#echo Проверка на наличие пакета imagemagick: $PKG_OK
if [ "" == "$PKG_OK" ]; then
	#echo "Ошибка. Требуется установить пакет imagemagick"  >&2; exit 1
	# если нужно установить 
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
	
fi

printf "\033c" # чистим экран

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

print_tab () # выводит на печать в таблицу
{   
	col_name1="      ФАЙЛ"
	col_name2="СТАТУС    "
	# выводим на печать.
	pad=$(printf '%0.1s' " "{1..80})
	padlength=80
	#Если выводим первый раз. То выводим заголовок. 
    if [[ $cnt -eq 1 ]]; then
    	printf '%0.1s' "-"{1..80} 
    	echo
    	printf '%s%*.*s%s\n' "$col_name1" 0 $((padlength - ${#col_name1} - ${#col_name2} )) "$pad" "$col_name2"
    	printf '%0.1s' "-"{1..80}
    	echo 
    fi
	printf '%s%*.*s%s\n' "$filename" 0 $((padlength - ${#filename} - ${#status} )) "$pad" "$status"
    #echo -e "										$status\r$filename "

}

get_sizes ()  # запрашивает размеры
{   
    
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
Вы указали ширину: $w высоту: $h
EOF
read -p "Всё верно? [Д/н] [Y/n] " -n 1 -r
echo    # перевод строки
if [[ $REPLY =~ ^[YyДд]$ ]]
then
	print_tab "ФАЙЛ" "СТАТУС"
	for i in "$DIR"/*; do
    	[ -f "$i" ] || continue 						# переход в начало цикла если не файл
       	filename="${i##*/}" 				   			# получаем название файла из full path
    	if  [[ ${filename^^}  =~ $PATTERN_IMG ]]        # конвертируем $filename в верхний регистр и сравниваем с regex 
    	then 
    	    ((cnt++ )) 									# счетчик картинок
    		 
       		{ #try 
    			#set +e
    			# проверяем файл на поврежденность. Если не поврежден, то статус OK
    			identify -verbose "$filename" > /dev/null 2>&1  &&  status="OK"
    		
			} || { #catch 
    			((cnt_corrupt++))						#счетчик поврежденных файлов
    			status="файл поврежден"
    			print_tab	# выводим на печать.
    			continue
    		}
    		 
			
			print_tab	# выводим на печать.
    		
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
	
	if [[ $cnt -eq 0 ]] # =
	then
		echo -e "Ошибка: В текущей дирректории не найдены файлы с изображениями." >&2; exit 1
	else
		echo
		echo -n "Конвертация завершена. "
		echo -e "Найдено $cnt картинок. Из них $cnt_corrupt поврежденных."
		exit 0
	fi
fi