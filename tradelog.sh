#! /bin/bash

export LC_NUMERIC="en_US.UTF-8"

export POSIXLY_CORRECT=yes

firstcheckFile=0; firstcheckT=0; flagT=0; flagA=0; timeA=0; flagB=0; timeB=20240000000000; flagW=0; width=0; fileispresentflag=0; filters=';'

for i in "$@" # filters and file names reading from arguemtns 
do

   if [ $flagT = 1 ] # summarization of all tickers in a single string ";tickername;|;tickername;|;tickername;|...|;tickername;"
   then
   tickerfilter=1
      if [ $firstcheckT = 1 ]
      then
         newticker=";$i;"
         filters=${filters}\|$newticker
         flagT=0
      fi
      if [ $firstcheckT = 0 ]
      then
         firstcheckT=1
         filters=";$i;"
         flagT=0
      fi
   fi

   if [ $flagA = 1 ] # setting timeA for "after" filter
   then
      timeA=$(echo $i | grep -o -E '[0-9]')
      timeA=$(echo $timeA | tr -d ' ')
      flagA=0
   fi

   if [ $flagB = 1 ] # setting timeB for "before" filter
   then
      timeB=$(echo $i | grep -o -E '[0-9]')
      timeB=$(echo $timeB | tr -d ' ')
      flagB=0
   fi

   if [ $flagW = 1 ] # setting width
   then 
      width=$i
   fi

   if [[ $i = "-t" ]] # if -t in arguments
   then 
      tickerfilter=1
      flagT=1
   fi

   if [[ $i = "-a" ]] # if -a in arguments
   then
      timeAfilter=1
      flagA=1
   fi

   if [[ $i = "-b" ]] # if -b in arguments
   then
      timeBfilter=1
      flagB=1
   fi

   if [[ $i = "-w" ]] # if -w in arguments
   then
      flagW=1
   fi

   if [ $(echo $i | grep txt) ] || [ $(echo $i | grep log) ] # file name reading (from arguments)
   then
      if [ $firstcheckFile = 1 ]
      then
         file="$file $i"
      fi
      if [ $firstcheckFile = 0 ]
      then
         firstcheckFile=1
         file=$i
         fileispresentflag=1
      fi   
   fi

done

# $file - file list; $filters - filter list; $width - width; $timeA - timeafter; $timeB - timebefore

xIFS=IFS
numberoflines=$(awk 'END{print NR}' $file)

declare -a price; declare -a amount; declare -a ticker; # arrays for pos...

operationcheck=0; tickerlistconstructor=';'; newtickerlistconstructor=';'; firstchecklisttick=0; timing=1; profit=0; counter=0; counterend=0; countercurrent=0; tmptiming=1; maxsize=0; sizeof=0

for i in "$@"
do

   if [[ $i = "list-tick" ]] # list tick case
   then
      operationcheck=1
      for ((i = 1 ; i <= $numberoflines ; i++))
      do  
         if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]] # search for time of operation (1. argument)
         then
            timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
            timing=$(echo $timing | tr -cd '0-9')
         fi
         line=$(awk "NR == $i{print}" $file)
         if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(echo $line | grep -E $filters) ]] # filter and time control on current $line
         then
            if [[ -z $(echo $line | grep -E $tickerlistconstructor) ]]  && [[ $firstchecklisttick -eq 1 ]] # for 2+. cases
            then
               awk "NR == $i{print}" $file | awk -F';' '{print $2}'
               newtickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
               tickerlistconstructor=${tickerlistconstructor}\|$newtickerlistconstructor
            elif [[ $(echo $line | grep -E $tickerlistconstructor) ]] && [[ $firstchecklisttick -eq 0 ]] # for 1. case
            then
               awk "NR == $i{print}" $file | awk -F';' '{print $2}'
               firstchecklisttick=1
               tickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
            fi
         fi
      done
   fi

   if [[ $i = "profit" ]] # profit case
   then
      operationcheck=1
      for ((i = 1 ; i <= $numberoflines ; i++))
      do
         if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]] # search for time of operation (1. argument)
         then
            timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
            timing=$(echo $timing | tr -cd '0-9')
         fi
         line=$(awk "NR == $i{print}" $file)
         if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(echo $line | grep -E $filters) ]] # filter and time control on current $line
         then
            profit=`echo "$line" | awk -F ';' -v res=$profit '{ if($3 == "sell") { temp+=$4*$6 }else{temp-=$4*$6} } END {printf("%.2f", res+temp)}'`
         fi
      done 
      echo $profit 
   fi
   if [[ $i = "pos" ]]; then # pos case
      operationcheck=1
      for ((i = 1 ; i <= $numberoflines ; i++)); do
         if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
            timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
            timing=$(echo $timing | tr -cd '0-9')
         fi
         line=$(awk "NR == $i{print}" $file)
         if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(echo $line | grep -E $filters) ]]; then # filter and time control on current $line
            if [[ -z $(echo $line | grep -E $tickerlistconstructor) ]]  && [[ $firstchecklisttick -eq 1 ]]; then # for 2+. cases
               ticker[$counter]=$(awk "NR == $i{print}" $file | awk -F';' '{print $2}') # new ticker found
               amount=0
               for ((j = 1 ; j <= $numberoflines ; j++)); do
                  if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
                     tmptiming=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
                     tmptiming=$(echo $tmptiming | tr -cd '0-9')
                  fi
                  tmpline=$(awk "NR == $j{print}" $file)
                  if [[ $(echo $tmpline | grep -E ${ticker[$counter]}) ]] && [[ $tmptiming > $timeA ]] && [[ $timeB > $tmptiming ]] && [[ $(echo $tmpline | grep -E $filters) ]]; then
                     amount=`echo "$tmpline" | awk -F ';' -v res=$amount '{ if($3 == "sell") { temp-=$6 }else{temp+=$6} } END {printf("%d", res+temp)}'` # sum of amount
                     counterend=$j
                  fi
               done
               price[$counter]=$(awk "NR == $counterend{print}" $file | awk -F ';' '{print $4}') # last price
               price[$counter]=`echo "$amount ${price[$counter]}" | awk -v price=${price[$counter]} -v amount=$amount '{printf("%.2f", amount*price)}'` # profit of all positions
               sizeof=${#price[$counter]}
               if [[ $sizeof > $maxsize ]]; then
                  maxsize=$sizeof
               fi
               newtickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
               tickerlistconstructor=${tickerlistconstructor}\|$newtickerlistconstructor # extension of tickerlist
               ((counter++))
            elif [[ $(echo $line | grep -E $tickerlistconstructor) ]] && [[ $firstchecklisttick -eq 0 ]]; then # for 1. case
               ticker[$counter]=$(awk "NR == $i{print}" $file | awk -F';' '{print $2}') # new ticker found
               amount=0
               for ((j = 1 ; j <= $numberoflines ; j++)); do
                  if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
                     tmptiming=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
                     tmptiming=$(echo $tmptiming | tr -cd '0-9')
                  fi
                  tmpline=$(awk "NR == $j{print}" $file)
                  if [[ $(echo $tmpline | grep -E ${ticker[$counter]}) ]] && [[ $tmptiming > $timeA ]] && [[ $timeB > $tmptiming ]] && [[ $(echo $tmpline | grep -E $filters) ]]; then
                     amount=`echo "$tmpline" | awk -F ';' -v res=$amount '{ if($3 == "sell") { temp-=$6 }else{temp+=$6} } END {printf("%d", res+temp)}'` # sum of amount
                     counterend=$j
                  fi
               done
               price[$counter]=$(awk "NR == $counterend{print}" $file | awk -F ';' '{print $4}') # last price
               price[$counter]=`echo "$amount ${price[$counter]}" | awk -v price=${price[$counter]} -v amount=$amount '{printf("%.2f", amount*price)}'` # profit of all positions
               sizeof=${#price[$counter]}
               if [[ $sizeof > $maxsize ]]; then
                  maxsize=$sizeof
               fi
               firstchecklisttick=1 
               tickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"   # extension of tickerlist
               ((counter++))
               
            fi   
         fi
      done
      
      for ((i = 0 ; i < $counter-1 ; i++)); do
         for ((j = 0 ; j < $counter-1 ; j++)); do
            comp=`awk -v num1=${price[$j]} -v num2=${price[$j+1]} 'BEGIN {printf "%.2f\n", num1 - num2}'`
            if [[ $(echo $comp | tr -cd "0-9, -" ) -lt 0 ]]; then
               tmpd=${price[$j]}
               tmpstr=${ticker[$j]}
               price[$j]=${price[$j+1]}
               ticker[$j]=${ticker[$j+1]}
               price[$j+1]=$tmpd
               ticker[$j+1]=$tmpstr
            fi
         done
      done
      maxsize=$((maxsize+2))
      for ((i = 0 ; i < $counter ; i++)); do
         printf "%-10s: %$maxsize.2f\n" "${ticker[$i]}" "${price[$i]}"
      done
   fi



   # if [[ $i = "last-price" ]] # last-price case
   # then
      # operationcheck=1

   # fi

   # if [[ $i = "hist-ord" ]] # hist-ord case
   # then
      # operationcheck=1

   # fi

   # if [[ $i = "graph-pos" ]] # graph-pos case
   # then
      # operationcheck=1

   # fi

   

done

if [[ operationcheck -eq 0 ]]; then
   for ((i = 1 ; i <= $numberoflines ; i++)); do
      if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
         timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
         timing=$(echo $timing | tr -cd '0-9')
      fi
      line=$(awk "NR == $i{print}" $file)
      if [[ $timeA < $timing ]] && [[ $timeB > $timing ]] && [[ $(echo $line | grep -E $filters) ]]; then # filter and time control on current $line
         echo $line
      fi
   done
fi

# while read line
# do
#    if [[ -n $(echo $line | grep $filters)] || ]
# done <$file



# нумерация в awk начинается с 1 (1. строка = NR == 1{print $shit})
#grep -E $filters $file #    <- grep template