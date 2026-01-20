term=$1
separate="==========================================================================================================\n"

if [ -f "cp2k.slurm" ]
then
  prefix=`grep PROJECT input.inp | awk '{print $2}' | tr -d '\r'`
fi

#if [[ $term == 'neb' ]]
if find . -maxdepth 1 -name "*BAND*" -print -quit | grep -q . && [ -f "cp2k.slurm" ]
then
  number=`grep NUMBER_OF_REPLICA input.inp | awk '{print $2}' | tr -d '\r'`
  st=`seq -w 1 $number`
  mapfile -t s <<< "$st"

  if [ -f "$prefix-BAND${s[0]}.out" ]
  then
    tail $prefix-BAND*.out
    echo -e $separate
    grep --color=always "\[ .*\]" $prefix-BAND${s[0]}.out | tail -4
    echo -e $separate
    grep --color=always "Step  Nr" $prefix-BAND${s[0]}.out | tail -1
    echo -e $separate
  fi

  if [ -f "$prefix-pos-Replica_nr_${s[0]}-1.xyz" ]
  then
    anumber=`head -n 1 $prefix-pos-Replica_nr_${s[0]}-1.xyz | awk '{print $1+2}'`

    >path1.xyz; for i in ${s[@]}; do head -n $anumber $prefix-pos-Replica_nr_$i-1.xyz>>path1.xyz; done; ,rp path1.xyz
    >path2.xyz; for i in ${s[@]}; do tail -n $anumber $prefix-pos-Replica_nr_$i-1.xyz>>path2.xyz; done; ,rp path2.xyz
    echo -e $separate

    > ene.dat
    enei=`grep ENERGY $prefix-BAND${s[0]}.out| tail -1| awk '{print $9}'`
    for i in ${s[@]}
    do
      ene=`grep ENERGY $prefix-BAND$i.out| tail -1| awk '{print $9}'`

      enec=`python -c "print(($ene - $enei)*27.2114)"`
      echo -e "$i\t$ene\t$enec" >> ene.dat
    done

    cat ene.dat
    echo -e $separate
  fi

else
  if [ -f "cp2k.slurm" ]
  then
    if [[ -e "./${prefix}-1.ener" ]]
    then
      tail out.out; tail ${prefix}-1.ener
      echo -e $separate
      ,rp ${prefix}-pos-1.xyz
      echo -e $separate
    else
      tail out.out
      echo -e $separate
      grep --color=always STEP out.out| tail
      echo -e $separate
      grep --color=always "Used time" out.out | tail
      echo -e $separate
      grep --color=always "Maximum step size        " out.out | tail -1
      grep --color=always "Convergence limit for maximum step size" out.out | tail -1
      grep --color=always "Maximum gradient        " out.out | tail -1
      grep --color=always "Convergence limit for maximum gradient" out.out | tail -1
      echo -e $separate
    fi
  elif [ -f "OUTCAR" ]
  then
    tail OUTCAR
    echo -e $separate
    tail OSZICAR
    echo -e $separate
  elif [ -f "lammps.slurm" ]
  then
    tail out.out
    echo -e $separate
    tail fp.dat
    echo -e $separate
  elif [ -f "abinit.slurm" ]
  then
    grep --color=always "max grad" out.out | tail
    echo -e $separate
    grep --color=always "wall_time" out.out | tail
    echo -e $separate
    grep --color=always "ETOT" out.out | tail
  fi
fi

squeue
