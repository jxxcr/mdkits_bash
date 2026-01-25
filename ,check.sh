separate="==========================================================================================================\n"

if [[ $# -eq 0 ]]
then
  declare -a list=("./")
else
  declare -a list=("$@")
fi

for path in "${list[@]}"
do
  #if [ -z "$term" ]
  #then
  #  path='./'
  #else
  #  path=$1
  #fi
  echo "#############################################################################################################"
  echo $path
  
  if [ -f "$path/cp2k.slurm" ]
  then
    prefix=`grep PROJECT $path/input.inp | awk '{print $2}' | tr -d '\r'`
  fi
  
  #if [[ $term == 'neb' ]]
  if find $path -maxdepth 1 -name "*BAND*" -print -quit | grep -q . && [ -f "cp2k.slurm" ]
  then
    number=`grep NUMBER_OF_REPLICA $path/input.inp | awk '{print $2}' | tr -d '\r'`
    st=`seq -w 1 $number`
    mapfile -t s <<< "$st"
  
    if [ -f "$path/$prefix-BAND${s[0]}.out" ]
    then
      tail $prefix-BAND*.out
      echo -e $separate
      grep --color=always "\[ .*\]" $path/$prefix-BAND${s[0]}.out | tail -4
      echo -e $separate
      grep --color=always "Step  Nr" $path/$prefix-BAND${s[0]}.out | tail -1
      echo -e $separate
    fi
  
    if [ -f "$path/$prefix-pos-Replica_nr_${s[0]}-1.xyz" ]
    then
      anumber=`head -n 1 $path/$prefix-pos-Replica_nr_${s[0]}-1.xyz | awk '{print $1+2}'`
  
      >$path/path1.xyz; for i in ${s[@]}; do head -n $anumber $path/$prefix-pos-Replica_nr_$i-1.xyz>>$path/path1.xyz; done; ,rp $path/path1.xyz
      >$path/path2.xyz; for i in ${s[@]}; do tail -n $anumber $path/$prefix-pos-Replica_nr_$i-1.xyz>>$path/path2.xyz; done; ,rp $path/path2.xyz
      echo -e $separate
  
      > $path/ene.dat
      enei=`grep ENERGY $path/$prefix-BAND${s[0]}.out| tail -1| awk '{print $9}'`
      for i in ${s[@]}
      do
        ene=`grep ENERGY $path/$prefix-BAND$i.out| tail -1| awk '{print $9}'`
  
        enec=`python -c "print(($ene - $enei)*27.2114)"`
        echo -e "$i\t$ene\t$enec" >> $path/ene.dat
      done
  
      cat $path/ene.dat
      echo -e $separate
    fi
  
  else
    if [ -f "$path/cp2k.slurm" ]
    then
      if [[ -e "$path/${prefix}-1.ener" ]]
      then
        tail $path/out.out; tail $path/${prefix}-1.ener
        echo -e $separate
        ,rp $path/${prefix}-pos-1.xyz
        echo -e $separate
      else
        tail $path/out.out
        echo -e $separate
        grep --color=always STEP $path/out.out| tail
        echo -e $separate
        grep --color=always "Used time" $path/out.out | tail
        echo -e $separate
        grep --color=always "Maximum step size        " $path/out.out | tail -1
        grep --color=always "Convergence limit for maximum step size" $path/out.out | tail -1
        grep --color=always "Maximum gradient        " $path/out.out | tail -1
        grep --color=always "Convergence limit for maximum gradient" $path/out.out | tail -1
        echo -e $separate
      fi
    elif [ -f "$path/OUTCAR" ]
    then
      tail $path/OUTCAR
      echo -e $separate
      tail $path/OSZICAR
      echo -e $separate
    elif [ -f "$path/lammps.slurm" ]
    then
      tail $path/out.out
      echo -e $separate
      tail $path/fp.dat
      echo -e $separate
    elif [ -f "$path/abinit.slurm" ]
    then
      grep --color=always "max grad" $path/out.out | tail
      echo -e $separate
      grep --color=always "wall_time" $path/out.out | tail
      echo -e $separate
      grep --color=always "converged" $path/out.out | tail
      echo -e $separate
      grep --color=always "ETOT" $path/out.out | tail
      echo -e $separate
    fi
  fi
done

squeue
