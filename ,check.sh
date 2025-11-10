term=$1

if [ -f "input.inp" ]
then
  prefix=`grep PROJECT input.inp | awk '{print $2}' | tr -d '\r'`
fi

#if [[ $term == 'neb' ]]
if find . -maxdepth 1 -name "*BAND*" -print -quit | grep -q .
then
  number=`grep NUMBER_OF_REPLICA input.inp | awk '{print $2}' | tr -d '\r'`
  st=`seq -w 1 $number`
  mapfile -t s <<< "$st"

  if [ -f "$prefix-BAND${s[0]}.out" ]
  then
    tail $prefix-BAND*.out; grep "\[ .*\]" $prefix-BAND${s[0]}.out | tail -4; grep "Step  Nr" $prefix-BAND${s[0]}.out | tail -1
  fi

  if [ -f "$prefix-pos-Replica_nr_${s[0]}-1.xyz" ]
  then
    anumber=`head -n 1 $prefix-pos-Replica_nr_${s[0]}-1.xyz | awk '{print $1+2}'`

    >path1.xyz; for i in ${s[@]}; do head -n $anumber $prefix-pos-Replica_nr_$i-1.xyz>>path1.xyz; done; ,rp path1.xyz
    >path2.xyz; for i in ${s[@]}; do tail -n $anumber $prefix-pos-Replica_nr_$i-1.xyz>>path2.xyz; done; ,rp path2.xyz

    > ene.dat
    enei=`grep ENERGY $prefix-BAND${s[0]}.out| tail -1| awk '{print $9}'`
    for i in ${s[@]}
    do
      ene=`grep ENERGY $prefix-BAND$i.out| tail -1| awk '{print $9}'`

      enec=`python -c "print(($ene - $enei)*27.2114)"`
      echo -e "$i\t$ene\t$enec" >> ene.dat
    done

    cat ene.dat
  fi

else
  if [ -f "out.out" ]
  then
    if [[ -e "./${prefix}-1.ener" ]]
    then
      tail out.out; tail ${prefix}-1.ener
      ,rp ${prefix}-pos-1.xyz
    else
      tail out.out
      grep STEP out.out| tail
      grep "Used time" out.out | tail
      grep "Maximum step size        " out.out | tail -1
      grep "Convergence limit for maximum step size" out.out | tail -1
      grep "Maximum gradient        " out.out | tail -1
      grep "Convergence limit for maximum gradient" out.out | tail -1
    fi
  fi
fi

squeue
