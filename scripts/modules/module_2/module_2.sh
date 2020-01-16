#!/bin/bash

if [ -d ~/cityapp/grass/global/module_2 ]
    then
        g.remove -f type=vector pattern=*
    else
        cp -r ~/cityapp/grass/skel/* ~/cityapp/grass/global/module_2
fi

RESOLUTION=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1)
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/module_2

# Get the points
# Message 1 #
kdialog --msgbox "$(cat $MESSAGES | head -n1 | tail -n1)"

HATARERTEK=$( cat valtozo/hatarertek )
MEGYE_KOD=$( cat valtozo/megye_kod )
MENTO_FIELD=$( cat valtozo/mento_field )

# Start html to define points

#Kérjük be a vizsgálandó települések nevét

zenity --info --text="Add meg azoknak a településeknek a nevét, melyeket be szeretnél vonni a vizsgálatba. Az egyes nevek után üss egy entert, ha pedig nem akarsz több nevet bevinni, akkor írd be, hogy ennyi és utána jöhet egy entert!" --title="modul_1" --width="400" height="100"

#echo "Add meg azoknak a településeknek a nevét, melyeket be szeretnél vonni a vizsgálatba. Az egyes nevek után üss egy entert, ha pedig nem akarsz több nevet bevinni, akkor írd be, hogy ennyi és utána üss egy entert!"	
echo ""
	until [ $NEVE = ennyi ]; do
		#echo ""		
		#echo "Település neve?"
	        #read NEVE
		telepuleslista=$(cat valtozo/telepuleslista_nevek)
		NEVE=$(zenity --entry --text="Add meg a figyelembe veendő település nevét.\n\n Eddig ezeket a településeket adtad meg:\n\n$telepuleslista" --title="modul_1 adatbekérés")		
		cat valtozo/telepulesnevek | grep -iw $NEVE | cut -f 1 >> valtozo/telepuleslista_azonosito
		cat valtozo/telepulesnevek | grep -iw $NEVE | cut -f 2 >> valtozo/telepuleslista_nevek
	done

# Állítsuk be a felbontást a megadott értékre.

g.region vect=telepuleshatarok nsres=$FELBONTAS ewres=$FELBONTAS

	#Távolítsuk el a maszkot,ha van

	if [ -e ../cellhd/MASK ]
		then
		g.remove rast=MASK	
	fi
	


	# Állítsuk be a felbontást a megadott értékre.

	g.region vect=telepuleshatarok nsres=$FELBONTAS ewres=$FELBONTAS

	#Készítsük el a változatlanul használandó térképeket
	

#	v.db.select -c map=telepulespontok layer=1 columns=NEV0 where="(MEGYE_KOD = $MEGYE_KOD) AND ($MENTO_FIELD > $HATARERTEK)" > valtozo/m1_nevek

#	v.db.select -c map=telepulespontok layer=1 columns=CAT where="(MEGYE_KOD = $MEGYE_KOD) AND ($MENTO_FIELD > $HATARERTEK)" > valtozo/m1_azonosito


		v.to.rast input=uthalozat output=temp_m1_uthalozat use=attr type=point,line layer=1 column=SPD rows=4096 --overwrite

		v.to.rast input=telepuleshatarok output=eredmeny_m1 use=val type=point,line,area layer=1 value=0 rows=4096 --overwrite
		
		r.mapcalc b_eredmeny=eredmeny_m1*1

		r.mapcalc temp_m1_copy_uthalozat=temp_m1_uthalozat*1

		r.null -c -r map=temp_m1_copy_uthalozat null=0
		
		g.copy vect=empty,telepulesek_m1

	#Itt jön a tulajdonképpeni lényeg:


		for i in $( cat valtozo/telepuleslista_azonosito ); do

			v.extract input=uthalozat output=pont_m1_$i type=point layer=1 where="(CAT=$i)" --quiet --overwrite
	
			v.to.rast input=pont_m1_$i output=pont_m1_$i use=attr type=point,line layer=1 column=SPD rows=4096 --overwrite

			r.null -c -r map=pont_m1_$i null=0            
	
			r.mapcalc temp_m1_utak_surlodasa="$FELBONTAS*3600/1000/temp_m1_copy_uthalozat"		
			
			r.cost -k input=temp_m1_utak_surlodasa output=ido.$i start_points=pont_m1_$i percent_memory=100 --overwrite
		
			r.null map=ido.$i null=1000000

			r.reclass input=ido.$i output=ido_m1_reclassed_$i rules=reclass/reclass_ido --overwrite 
			
				cat valtozo/telepulesnevek | grep -iw $i | cut -f 2 > valtozo/temp_m1_telepulesnev

				TEMP_TELEPULESNEV=$( cat valtozo/temp_m1_telepulesnev)

				echo "1:$TEMP_TELEPULESNEV" > valtozo/temp_recode

				r.category map=ido_m1_reclassed_$i rules=valtozo/temp_recode

			r.cross input=ido_m1_reclassed_$i,b_eredmeny output=a_eredmeny --overwrite

			g.copy rast=a_eredmeny,b_eredmeny --overwrite
			
			r.mapcalc eredmeny_m1=eredmeny_m1+ido_m1_reclassed_$i
					
			v.patch -a input=pont_m1_$i output=telepulesek_m1 --overwrite
			
		done

	sed 's/category 0;//g' ../cats/a_eredmeny > valtozo/temp_a_eredmeny
	
	sed 's/; category 0//g' valtozo/temp_a_eredmeny > valtozo/temp_aa_eredmeny
	
	cat valtozo/temp_aa_eredmeny > ../cats/a_eredmeny

#	rm -f valtozo/*temp*

#	r.cross input=a_eredmeny,eredmeny_m1, output=mentoterkep_1 --overwrite

	r.colors map=eredmeny_m1 rules=szinek/szinek_ido_reclassed

	r.colors map=a_eredmeny rules=szinek/szinek_ido_reclassed

	d.rast map=eredmeny_m1
	d.vect map=telepulesek_m1 color=0:0:0 lcolor=0:0:0 fcolor=170:170:170 display=shape type=point,line,boundary,centroid,area icon=basic/circle size=5 layer=1 lsize=8 xref=left yref=center llayer=1
#	r.category map=eredmeny_m1 fs=tab raster=a_eredmeny
				

	##########################
	##Töröljük, ami nem kell##
	##########################
	echo
	echo
	echo "Törlöm a szükségtelen állományokat"
#	g.mremove -f vect=*temp* 
#	g.mremove -f rast=*temp*
#	g.remove -f rast=temp_uthalozat
#	g.remove -f rast=temp_copy_uthalozat
#	g.remove -f MASK

	clear

exit


