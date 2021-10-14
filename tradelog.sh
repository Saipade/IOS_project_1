#!/bin/sh
export LC_NUMERIC="en_US.UTF-8"

export POSIXLY_CORRECT=yes

firstcheckFile=0; firstcheckT=0; flagT=0; flagA=0; timeA=0; flagB=0; flagH=0; timeB=20240000000000; flagW=0; width=0; fileispresentflag=0; filters=';'; widthisenabled=0
echo `date`
for i in "$@" # filters and file names reading from arguemtns 
do

   if [[ $flagT = 1 ]]; then # summarization of all tickers in a single string ";tickername;|;tickername;|;tickername;|...|;tickername;"
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
   if [[ $flagA = 1 ]]; then # setting timeA for "after" filter
      timeA=$(echo $i | grep -o -E '[0-9]')
      timeA=$(echo $timeA | tr -d ' ')
      flagA=0
   fi
   if [[ $flagB = 1 ]]; then # setting timeB for "before" filter
      timeB=$(echo $i | grep -o -E '[0-9]')
      timeB=$(echo $timeB | tr -d ' ')
      flagB=0
   fi
   if [[ $flagW = 1 ]]; then # setting width
      width=$i
      flagW=0
      widthisenabled=1
   fi
   if [[ $i = "-t" ]]; then # if -t is present among arguments
      tickerfilter=1
      flagT=1
   fi
   if [[ $i = "-a" ]]; then # if -a is present among arguments
      timeAfilter=1
      flagA=1
   fi
   if [[ $i = "-b" ]]; then # if -b is present among arguments
      timeBfilter=1
      flagB=1
   fi
   if [[ $i = "-w" ]]; then # if -w is present among arguments
      flagW=1
   fi
   if [[ $i = "-h" ]] || [[ $i = "--help" ]]; then # if -h or --help is present among arguments
      flagH=1
   fi
   if [ $(echo $i | grep .txt) ] || [ $(echo $i | grep .log) ] # file name reading (from arguments)
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
if [[ $fileispresentflag -eq 0 ]]; then
   read file
   fileispresentflag=1
fi

# $file - file list ... $filters - filter list ... $width - width ... $timeA - timeafter ... $timeB - timebefore

declare -a price; declare -a amount; declare -a ticker; declare -a tickerlist; declare -a sortedticker; declare -a sign # arrays

operationcheck=0; tickerlistconstructor=';'; newtickerlistconstructor=';'; firstchecklisttick=0; timing=1; profit=0; counter=0; counterend=0; tmptiming=1; maxsize=0; sizeof=0; largestnumber=0

if [[ $fileispresentflag -eq 1 ]] && [[ $flagH -eq 0 ]]; then
   numberoflines=$(awk 'END{print NR}' $file)
   for i in "$@"; do

      if [[ $i = "list-tick" ]]; then # list tick case
         operationcheck=1
         for ((i = 1 ; i <= $numberoflines ; i++)); do
            if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
               timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
               timing=$(echo $timing | tr -cd '0-9')
            fi
            if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(awk "{if(NR==$i) print }" $file | grep -E $filters) ]]; then # filter and time control on current line
               if [[ -z $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]]  && [[ $firstchecklisttick -eq 1 ]]; then # for 2+. cases
                  ticker[$counter]=$(awk "NR == $i{print}" $file | awk -F';' '{print $2}')
                  newtickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  tickerlistconstructor=${tickerlistconstructor}\|$newtickerlistconstructor
                  ((counter++))
               elif [[ $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]] && [[ $firstchecklisttick -eq 0 ]]; then # for 1. case
                  ticker[$counter]=$(awk "NR == $i{print}" $file | awk -F';' '{print $2}')
                  firstchecklisttick=1
                  tickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  ((counter++))
               fi
            fi
         done
         sortedticker=($(echo "${ticker[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')) # sorted by alphabet
         for ((i = 0 ; i < $counter ; i++)); do
            printf "%s\n" "${sortedticker[$i]}"
         done
      fi

      if [[ $i = "profit" ]]; then # profit case
         operationcheck=1
         for ((i = 1 ; i <= $numberoflines ; i++)); do
            if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
               timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
               timing=$(echo $timing | tr -cd '0-9')
            fi
            if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(awk "{if(NR==$i) print }" $file | grep -E $filters) ]]; then # filter and time control on current line
               profit=`awk "NR == $i{print}" $file | awk -F ';' -v res=$profit '{ if($3 == "sell") { temp+=$4*$6 }else{temp-=$4*$6} } END {printf("%.2f", res+temp)}'`
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
            if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(awk "{if(NR==$i) print }" $file | grep -E $filters) ]]; then # filter and time control on current line
               if [[ -z $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]]  && [[ $firstchecklisttick -eq 1 ]]; then # for 2+. cases
                  ticker[$counter]=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');" # new ticker found
                  amount=0
                  for ((j = 1 ; j <= $numberoflines ; j++)); do
                     if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
                        tmptiming=$(awk "NR == $j{print}" $file | awk -F';' '{print $1}')
                        tmptiming=$(echo $tmptiming | tr -cd '0-9')
                     fi
                     if [[ $(awk "{if(NR==$j) print }" $file | grep -E ${ticker[$counter]}) ]] && [[ $tmptiming > $timeA ]] && [[ $timeB > $tmptiming ]] && [[ $(awk "{if(NR==$j) print }" $file | grep -E $filters) ]]; then
                        amount=`awk "NR == $j{print}" $file | awk -F ';' -v res=$amount '{ if($3 == "sell") { temp-=$6 }else{temp+=$6} } END {printf("%d", res+temp)}'` # sum of amount
                        counterend=$j
                     fi
                  done
                  ticker[$counter]=$(echo ${ticker[$counter]} | tr -cd 'A-Z')
                  price[$counter]=$(awk "NR == $counterend{print}" $file | awk -F ';' '{print $4}') # last price
                  price[$counter]=`echo "$amount ${price[$counter]}" | awk -v price=${price[$counter]} -v amount=$amount '{printf("%.2f", amount*price)}'` # profit of all positions
                  sizeof=${#price[$counter]}
                  if [[ $sizeof -gt $maxsize ]]; then
                     maxsize=$sizeof
                  fi
                  newtickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  tickerlistconstructor=${tickerlistconstructor}\|$newtickerlistconstructor # extension of tickerlist
                  ((counter++))
               elif [[ $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]] && [[ $firstchecklisttick -eq 0 ]]; then # for 1. case
                  ticker[$counter]=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');" # new ticker found
                  amount=0
                  for ((j = 1 ; j <= $numberoflines ; j++)); do
                     if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
                        tmptiming=$(awk "NR == $j{print}" $file | awk -F';' '{print $1}')
                        tmptiming=$(echo $tmptiming | tr -cd '0-9')
                     fi
                     if [[ $(awk "{if(NR==$j) print }" $file | grep -E ${ticker[$counter]}) ]] && [[ $tmptiming > $timeA ]] && [[ $timeB > $tmptiming ]] && [[ $(awk "{if(NR==$j) print }" $file | grep -E $filters) ]]; then
                        amount=`awk "NR == $j{print}" $file | awk -F ';' -v res=$amount '{ if($3 == "sell") { temp-=$6 }else{temp+=$6} } END {printf("%d", res+temp)}'` # sum of amount
                        counterend=$j
                     fi
                  done
                  ticker[$counter]=$(echo ${ticker[$counter]} | tr -cd 'A-Z')
                  price[$counter]=$(awk "NR == $counterend{print}" $file | awk -F ';' '{print $4}') # last price
                  price[$counter]=`echo "$amount ${price[$counter]}" | awk -v price=${price[$counter]} -v amount=$amount '{printf("%.2f", amount*price)}'` # profit of all positions
                  sizeof=${#price[$counter]}
                  if [[ $sizeof -gt $maxsize ]]; then
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
         for ((i = 0 ; i < $counter ; i++)); do
            printf "%-10s: %${maxsize}.2f\n" "${ticker[$i]}" "${price[$i]}"
         done
      fi

      if [[ $i = "last-price" ]]; then # last-price case
         operationcheck=1
         for ((i = 1 ; i <= $numberoflines ; i++)); do
            if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
               timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
               timing=$(echo $timing | tr -cd '0-9')
            fi
            if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(awk "{if(NR==$i) print }" $file | grep -E $filters) ]]; then # filter and time control on current line
               if [[ -z $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]]  && [[ $firstchecklisttick -eq 1 ]]; then # for 2+. cases
                  ticker[$counter]=$(awk "NR == $i{print}" $file | awk -F';' '{print $2}')
                  newtickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  tickerlistconstructor=${tickerlistconstructor}\|$newtickerlistconstructor
                  ((counter++))
               elif [[ $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]] && [[ $firstchecklisttick -eq 0 ]]; then # for 1. case
                  ticker[$counter]=$(awk "NR == $i{print}" $file | awk -F';' '{print $2}')
                  firstchecklisttick=1
                  tickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  ((counter++))
               fi
            fi
         done
         sortedticker=($(echo "${ticker[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')) # sorted by alphabet
         for ((i = 0 ; i < $counter ; i++)); do
            for ((j = 1 ; j <= $numberoflines ; j++)); do
               if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
                  tmptiming=$(awk "NR == $j{print}" $file | awk -F';' '{print $1}')
                  tmptiming=$(echo $tmptiming | tr -cd '0-9')
               fi
               if [[ $(awk "{if(NR==$j) print }" $file | grep -E ${sortedticker[$i]}) ]] && [[ $tmptiming > $timeA ]] && [[ $timeB > $tmptiming ]] && [[ $(awk "{if(NR==$j) print }" $file | grep -E $filters) ]]; then
                  counterend=$j
               fi
            done
            price[$i]=$(awk "NR == $counterend{print}" $file | awk -F ';' '{print $4}') # last price
            sizeof=${#price[$i]}
            if [[ $sizeof -gt $maxsize ]]; then
               maxsize=$sizeof
            fi
         done
         for ((i = 0 ; i < $counter ; i++)); do
            printf "%-10s: %${maxsize}.2f\n" "${sortedticker[$i]}" "${price[$i]}"
         done 
      fi

      if [[ $i = "hist-ord" ]]; then # hist-ord case
         operationcheck=1
         for ((i = 1 ; i <= $numberoflines ; i++)); do
            if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
               timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
               timing=$(echo $timing | tr -cd '0-9')
            fi
            if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(awk "{if(NR==$i) print }" $file | grep -E $filters) ]]; then # filter and time control on current line
               if [[ -z $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]]  && [[ $firstchecklisttick -eq 1 ]]; then # for 2+. cases
                  ticker[$counter]=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  newtickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  tickerlistconstructor=${tickerlistconstructor}\|$newtickerlistconstructor
                  ((counter++))
               elif [[ $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]] && [[ $firstchecklisttick -eq 0 ]]; then # for 1. case
                  ticker[$counter]=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  firstchecklisttick=1
                  tickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  ((counter++))
               fi
            fi
         done
         sortedticker=($(echo "${ticker[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')) # sorted by alphabet
         for ((i = 0 ; i < $counter ; i++)); do
            for ((j = 1 ; j <= $numberoflines ; j++)); do
               if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
                  tmptiming=$(awk "NR == $j{print}" $file | awk -F';' '{print $1}')
                  tmptiming=$(echo $tmptiming | tr -cd '0-9')
               fi
               if [[ $(awk "{if(NR==$j) print }" $file | grep -E ${sortedticker[$i]}) ]] && [[ $tmptiming > $timeA ]] && [[ $timeB > $tmptiming ]] && [[ $(awk "{if(NR==$j) print }" $file | grep -E $filters) ]]; then
                  ((amount[$i]++)) # number of transactions for each ticker
               fi
            done
         done
         
         for ((i = 0 ; i < $counter ; i++)); do
            sortedticker[$i]=$(echo ${sortedticker[$i]} | tr -cd 'A-Z') 
         done
         if [[ $widthisenabled -eq 1 ]]; then
            for ((i = 0 ; i < $counter ; i++)); do # finding largest nubmer
               if [[ ${amount[$i]} -gt $largestnumber ]]; then
                  largestnumber=${amount[$i]}
               fi
            done
            for ((i = 0 ; i < $counter ; i++)); do # applying new width (newwidth = currentnumber * width / largestnumber) 
               amount[$i]=$((amount[$i] * width / largestnumber))
            done
         fi
         for ((i = 0 ; i < $counter ; i++)); do
            printf "%-10s: " "${sortedticker[$i]}"
            for ((j = 0 ; j < ${amount[$i]} ; j++)); do
               printf "#"
            done
            printf "\n"
         done 
      fi

      if [[ $i = "graph-pos" ]]; then # graph-pos case
         operationcheck=1
         for ((i = 1 ; i <= $numberoflines ; i++)); do
            if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
               timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
               timing=$(echo $timing | tr -cd '0-9')
            fi
            if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(awk "{if(NR==$i) print }" $file | grep -E $filters) ]]; then # filter and time control on current line
               if [[ -z $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]]  && [[ $firstchecklisttick -eq 1 ]]; then # for 2+. cases
                  ticker[$counter]=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  newtickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  tickerlistconstructor=${tickerlistconstructor}\|$newtickerlistconstructor
                  ((counter++))
               elif [[ $(awk "{if(NR==$i) print }" $file | grep -E $tickerlistconstructor) ]] && [[ $firstchecklisttick -eq 0 ]]; then # for 1. case
                  ticker[$counter]=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  firstchecklisttick=1
                  tickerlistconstructor=";$(awk "NR == $i{print}" $file | awk -F';' '{print $2}');"
                  ((counter++))
               fi
            fi
         done
         sortedticker=($(echo "${ticker[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')) # sorted by alphabet
         for ((i = 0 ; i < $counter ; i++)); do
            amount=0
            for ((j = 1 ; j <= $numberoflines ; j++)); do
               if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
                  tmptiming=$(awk "NR == $j{print}" $file | awk -F';' '{print $1}')
                  tmptiming=$(echo $tmptiming | tr -cd '0-9')
               fi
               if [[ $(awk "{if(NR==$j) print }" $file | grep -E ${sortedticker[$i]}) ]] && [[ $tmptiming > $timeA ]] && [[ $timeB > $tmptiming ]] && [[ $(awk "{if(NR==$j) print }" $file | grep -E $filters) ]]; then
                  amount=`awk "NR == $j{print}" $file | awk -F ';' -v res=$amount '{ if($3 == "sell") { temp-=$6 }else{temp+=$6} } END {printf("%d", res+temp)}'` # sum of amount
                  counterend=$j
               fi
            done
            price[$i]=$(awk "NR == $counterend{print}" $file | awk -F ';' '{print $4}') # last price
            price[$i]=`echo "$amount ${price[$i]}" | awk -v price=${price[$i]} -v amount=$amount '{printf("%.2f", amount*price)}'` # profit of all positions
            price[$i]=${price[$i]%.*}
         done
         for ((i = 0 ; i < $counter ; i++)); do
            sortedticker[$i]=$(echo ${sortedticker[$i]} | tr -cd 'A-Z') # sorting tickers by alphabet
         done
         for ((i = 0 ; i < $counter ; i++)); do # abs(${price[$]}). all signes (+/-) to another array
            if [[ ${price[$i]} -gt 0 ]]; then
               sign[$i]="+"
            fi
            if [[ ${price[$i]} -lt 0 ]]; then
               price[$i]=$(echo ${price[$i]#-})
               sign[$i]="-"
            fi
         done
         if [[ $widthisenabled -eq 1 ]]; then
            for ((i = 0 ; i < $counter ; i++)); do # finding largest nubmer
               if [[ ${price[$i]} -gt $largestnumber ]]; then
                  largestnumber=${price[$i]}
               fi
            done
            for ((i = 0 ; i < $counter ; i++)); do # applying new width (newwidth = currentnumber * width / largestnumber) 
               price[$i]=$((price[$i] * width / largestnumber))
            done
            for ((i = 0 ; i < $counter ; i++)); do
               printf "%-10s: " "${sortedticker[$i]}"
               for ((j = 0 ; j < ${price[$i]} ; j++)); do
                  if [[ ${sign[$i]} = "-" ]]; then
                     printf "!"
                  fi
                  if [[ ${sign[$i]} = "+" ]]; then
                     printf "#"
                  fi
               done
               printf "\n"
            done
         fi
         if [[ $widthisenabled -eq 0 ]]; then
            for ((i = 0 ; i < $counter ; i++)); do
               printf "%-10s: " "${sortedticker[$i]}"
               while [[ ${price[$i]} -gt 1000 ]]; do
                  if [[ ${sign[$i]} = "-" ]]; then
                     printf "!"
                  fi
                  if [[ ${sign[$i]} = "+" ]]; then
                     printf "#"
                  fi
                  price[$i]=$((price[$i]-1000))
               done
               printf "\n"
            done
         fi
      fi
   done
fi
if [[ $operationcheck -eq 0 ]] && [[ $flagH -eq 0 ]]; then # no command case
   for ((i = 1 ; i <= $numberoflines ; i++)); do
      if [[ $timeAfilter -eq 1 ]] || [[ $timeBfilter -eq 1 ]]; then # search for time of operation (1. argument)
         timing=$(awk "NR == $i{print}" $file | awk -F';' '{print $1}')
         timing=$(echo $timing | tr -cd '0-9')
      fi
      if [[ $timing > $timeA ]] && [[ $timeB > $timing ]] && [[ $(awk "{if(NR==$i) print }" $file | grep -E $filters) ]]; then # filter and time control on current line
         awk "{if(NR==$i) print }" $file
      fi
   done
fi
if [[ $operationcheck -eq 0 ]] && [[ $flagH -eq 1 ]]; then # help case
   printf "\nPŘÍKAZ může být jeden z:
list-tick – výpis seznamu vyskytujících se burzovních symbolů, tzv. “tickerů”.
profit – výpis celkového zisku z uzavřených pozic.
pos – výpis hodnot aktuálně držených pozic seřazených sestupně dle hodnoty.
last-price – výpis poslední známé ceny pro každý ticker.
hist-ord – výpis histogramu počtu transakcí dle tickeru.
graph-pos – výpis grafu hodnot držených pozic dle tickeru.

FILTR může být kombinace následujících:
-a DATETIME – after: jsou uvažovány pouze záznamy PO tomto datu (bez tohoto data). DATETIME je formátu YYYY-MM-DD HH:MM:SS.
-b DATETIME – before: jsou uvažovány pouze záznamy PŘED tímto datem (bez tohoto data).
-t TICKER – jsou uvažovány pouze záznamy odpovídající danému tickeru. Při více výskytech přepínače se bere množina všech uvedených tickerů.
-w WIDTH – u výpisu grafů nastavuje jejich šířku, tedy délku nejdelšího řádku na WIDTH. Tedy, WIDTH musí být kladné celé číslo. Více výskytů přepínače je chybné spuštění.
-h a --help vypíšou nápovědu s krátkým popisem každého příkazu a přepínače.\n"
fi
