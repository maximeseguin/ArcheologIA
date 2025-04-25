@echo off
:: permet de lire des variables qui ont précédemment évolué dans le script (avec ça on peut les mettre à jour après)
setlocal enabledelayedexpansion





rem ------ Traitement du fichier texte -------

rem echo Début de triage
set fichier=Dalles1.txt
set "fichier_temp=temp_sortie.txt"
set "fichier_tri=fichier_tri.txt"

if exist "%fichier_temp%" del "%fichier_temp%"
if exist "%fichier_tri%" del "%fichier_tri%"



rem On cherche dans la première partie de la ligne avant la virgule (nomFichier)
rem token sert a séparer la ligne en plusieurs parties avec la délimitation donnée après ici delims = virgule  ((V-C. Les boucles de recherche))
rem %%A = nom du fichier extrait
rem %%B = lien de telechargement du fichier extrait 
rem %%C et %%D sont la 3eme et 4eme partie (séparées par _) du nom du fichier donc les coordonnées (C = X et D = Y)
for /f "tokens=1,2 delims=," %%A in (%fichier%) do (
    set "nomFichier=%%A"
    set "lien=%%B"
	
rem on crée un fichier temp pour trier, on refera un fichier correct après
rem num 1 c'est X et num 2 c'est Y
    for /f "tokens=3,4 delims=_" %%C in ("!nomFichier!") do (
        set "num1=%%C"
		rem echo %%C
        set "num2=%%D"
		rem echo %%D
        echo !num1! !num2! !nomFichier!,!lien! >> "%fichier_temp%"
		rem echo !num1! !num2! !nomFichier! !lien!
    )
)

rem trie le fichier a gauche, /o redirige le résultat dans le fichier de droite (en l'écrasant)
sort "%fichier_temp%" /o "%fichier_temp%"

rem on reforme le fichier
rem le 3eme membre ici dans :
rem !num1! !num2! !nomFichier!,!lien! est !nomFichier!,!lien!
rem donc notre fichier trié sera de la forme : !nomFichier!,!lien! comme le fichier d'entrée
for /f "tokens=3 delims= " %%E in (%fichier_temp%) do (
    echo %%E >> "%fichier_tri%"
	rem echo %%E
)

del "%fichier_temp%"
rem echo %fichier_tri% fini de trier





rem ------ Traitement des dalles -------

rem même boucle qu'au dessus pour les telecharger mais j'ai voulu bien séparer

set /a numDalle=0

rem lit chaque ligne du fichier texte

for /f "tokens=1,2 delims=," %%A in (%fichier_tri%) do (
    set nomFichier=%%A
    set url=%%B
  for /f "tokens=3,4 delims=_" %%X in ("!nomFichier!") do (
        set "X=%%X"
        set "Y=%%Y"
		
		



rem ------ Dalles centrales -------
echo Début de téléchargement dalle centrale		
if not exist "!nomFichier!" (
    echo Telechargement du fichier: !nomFichier!
	echo donc de la dalle !X!_!Y!
    curl -x http://proxy.culture.fr:8000 -O !url!  
) else (
    echo Fichier deja telecharge: !nomFichier!
)	
echo fin du téléchargement	



rem ------ Dalles voisines -------
echo Début de traitement dalles voisines	
set /a minX=1!X!-10000
set /a minY=1!Y!-10000	
	
set /a place_dalle=0
set /a numDalle+=1	

for %%x in (-1 0 1) do (
	for %%y in (-1 0 1) do (
		rem pour ne pas prendre la dalle centrale
		if not "%%x%%y"=="00" (
		rem echo %%x
		set /a voisinX=!minX!+%%x
		set /a voisinY=!minY!+%%y
		rem ajoute 4 zéros devant pour prendre en compte la possibilité que le chiffre soit nul
		set "voisinX=0000!voisinX!"
		set "voisinY=0000!voisinY!"
		rem echo !voisinX!
		rem ~-4 signifie "prends les 4 derniers caractères", position négative = à partir de la fin donc on remet au bon format
		set "voisinX=!voisinX:~-4!"
		set "voisinY=!voisinY:~-4!"
		rem echo !voisinX!
		set /a place_dalle=!place_dalle!+1
		echo Recherche de la dalle voisine numero !place_dalle! de coordonnees : X = !voisinX!, Y = !voisinY!
		rem echo !place_dalle!
		echo.
		rem echo recherche de LHD_FXX_!voisinX!_!voisinY!
		rem le cmd /v:on /c permet d'activer de force l'expansion retardée : si on ne le met pas on aura une erreur parce que voisin X et Y ne seront pas mis à jour, donc la condition de la boucle sera fausse  
		rem trouver et afficher le lien correspondant dans fichier_tri.txt
		for /f "tokens=1,2 delims=," %%f in ('cmd /v:on /c "findstr /i /c:!voisinX!_!voisinY! %fichier_tri%"') do (
		set "nomFichier=%%f"
		set "lien=%%g"
		rem echo !nomFichier!
		rem echo !place_dalle!
		rem echo !lien!
echo fin traitement dalle voisine		
		
echo début telechargement dalle voisine		
if not exist "!nomFichier!" (
    echo Telechargement de la dalle voisine: !nomFichier!
	echo donc de la dalle voisine !voisinX!_!voisinY!
	rem télécharger la dalle centrale, -0 enregistre le fichier avec son nom d'origine
	rem /!\ ici on a une sécurité proxy 
    curl -x http://proxy.culture.fr:8000 -O !lien!
) else (
    echo Dalle voisine deja telechargee: !nomFichier!
)
echo fin telechargement dalle voisine		




rem ------ Supression des dalles inutiles -------
echo début Supression dalle 	

set "Xactuel=%%X"
set /a "X_supp_num=1!Xactuel!-10000-2"
set "X_supp=0000!X_supp_num!"
set "X_supp=!X_supp:~-4!"

echo Suppression des dalles de la colonne !X_supp!...

for %%F in (LHD_FXX_!X_supp!_*_PTS_*_LAMB93_IGN69.copc.laz) do (
    if exist "%%F" (
        echo Suppression de %%F
        del "%%F"
    )
)
echo fin suppression
 



	
	
		
rem ------ Rognage dalles voisines -------
echo début rognage dalles voisines		
		set INPUT_LAZ=!nomFichier!
		
		if !place_dalle! == 1 (
							
					rem dès qu'on voudra faire une opération sur un chiffre on devra repasser par une conversion
					rem on ajoute 1 pour forcer la base 10, on soustrait 10000 pour revenir a la valeur de base		
					rem voisinX est octal, il faut le convertir en décimal					
					set /a "Xnum=1!voisinX!-10000"
					rem echo !Xnum!
					rem on ajoute des zéros devant pour envisager que le nombre contienne des 0 devant
					set "Xnum=0000!Xnum!" 
					rem on ne veut garder que les 4 premiers chiffres et on complète avec les 3 derniers chiffres attendus
					set "Xmin=!Xnum:~-4!950"
					
					set /a "Xnum2=1!voisinX!-10000+1"
					set "Xnum2=0000!Xnum2!" 
					set "Xmax=!Xnum2:~-4!000"

					set /a "Ynum=1!voisinY!-10000-1"
					set "Ynum=0000!Ynum!" 	
					set "Ymin=!Ynum:~-4!950"

					set /a "Ymax=!voisinY!000"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
					
					set OUTPUT_LAZ=D!numDalle!outputdalle1.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)
					
					

                ) else if !place_dalle! == 2 (
					
					set /a "Xnum=1!voisinX!-10000"
					set "Xnum=0000!Xnum!" 
					set "Xmin=!Xnum:~-4!950"
					
					set /a "Xnum2=1!voisinX!-10000+1"
					set "Xnum2=0000!Xnum2!" 
					set "Xmax=!Xnum2:~-4!000"
					
					set /a "Ynum=1!voisinY!-10000-1"
					set "Ynum=0000!Ynum!" 	
					set "Ymin=!Ynum:~-4!000"
					
					set /a "Ymax=!voisinY!000"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
					
					set OUTPUT_LAZ=D!numDalle!outputdalle2.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)

                ) else if !place_dalle!==3 (
				
					set /a "Xnum=1!voisinX!-10000"
					set "Xnum=0000!Xnum!" 
					set "Xmin=!Xnum:~-4!950"
					
					set /a "Xnum2=1!voisinX!-10000+1"
					set "Xnum2=0000!Xnum2!" 
					set "Xmax=!Xnum2:~-4!000"
					
					set /a "Ynum=1!voisinY!-10000-1"
					set "Ynum=0000!Ynum!" 	
					set "Ymin=!Ynum:~-4!000"
					
					set /a "Ynum2=1!voisinY!-10000-1"
					set "Ynum2=0000!Ynum2!" 	
					set "Ymax=!Ynum2:~-4!050"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
					
					set OUTPUT_LAZ=D!numDalle!outputdalle3.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)

                ) else if !place_dalle! == 4 (
						
					set "Xmin=!voisinX!000"	
					
					set /a "Xnum=1!voisinX!-10000+1"  
					set "Xnum=0000!Xnum!"  
					set "Xmax=!Xnum:~-4!000"
					
					set /a "Ynum=1!voisinY!-10000-1"
					set "Ynum=0000!Ynum!" 	
					set "Ymin=!Ynum:~-4!950"
					
					set /a "Ymax=!voisinY!000"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
					
					set OUTPUT_LAZ=D!numDalle!outputdalle4.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)
                   
                )else if !place_dalle! == 5 (
							
					set "Xmin=!voisinX!000"				
					
					set /a "Xnum=1!voisinX!-10000+1"  
					set "Xnum=0000!Xnum!"  
					set "Xmax=!Xnum:~-4!000"
					
					set /a "Ynum=1!voisinY!-10000-1" 
					set "Ynum=0000!Ynum!" 	
					set "Ymin=!Ynum:~-4!000"		
					
					set /a "Ynum2=1!voisinY!-10000-1"
					set "Ynum2=0000!Ynum2!" 	
					set "Ymax=!Ynum2:~-4!050"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
			
					set OUTPUT_LAZ=D!numDalle!outputdalle5.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)
					
                )else if !place_dalle! == 6 (
                    								
					set /a "Xnum=1!voisinX!-10000"
					set "Xnum=0000!Xnum!" 
					set "Xmin=!Xnum:~-4!000"
					
					set /a "Xnum2=1!voisinX!-10000"
					set "Xnum2=0000!Xnum!" 
					set "Xmax=!Xnum:~-4!050"
					
					set /a "Ynum=1!voisinY!-10000-1"
					set "Ynum=0000!Ynum!" 	
					set "Ymin=!Ynum:~-4!950"
					
					set /a "Ymax=!voisinY!000"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
					
					set OUTPUT_LAZ=D!numDalle!outputdalle6.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)
					
                )else if !place_dalle! == 7 (
					
					set /a "Xnum=1!voisinX!-10000"
					set "Xnum=0000!Xnum!" 
					set "Xmin=!Xnum:~-4!000"
					
					set /a "Xnum2=1!voisinX!-10000"
					set "Xnum2=0000!Xnum!" 
					set "Xmax=!Xnum:~-4!050"
					
					set /a "Ynum=1!voisinY!-10000-1"
					set "Ynum=0000!Ynum!" 
					set "Ymin=!Ynum:~-4!000"
					
					set /a "Ymax=!voisinY!000"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
					
					set OUTPUT_LAZ=D!numDalle!outputdalle7.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)
					
                )else (
					
					set /a "Xnum=1!voisinX!-10000"
					set "Xnum=0000!Xnum!" 
					set "Xmin=!Xnum:~-4!000"
					
					set /a "Xnum2=1!voisinX!-10000"
					set "Xnum2=0000!Xnum!" 
					set "Xmax=!Xnum:~-4!050"
					
					set /a "Ynum=1!voisinY!-10000-1" 
					set "Ynum=0000!Ynum!" 	
					set "Ymin=!Ynum:~-4!000"		
					
					set /a "Ynum2=1!voisinY!-10000-1"
					set "Ynum2=0000!Ynum!" 	
					set "Ymax=!Ynum2:~-4!050"
					
					rem echo !Xmin! et !Xmax! et !Ymin! et !Ymax!
					
					set OUTPUT_LAZ=D!numDalle!outputdalle8.laz
					
					if not exist "!OUTPUT_LAZ!" (
					pdal translate --filters.crop.bounds="([!Xmin!,!Xmax!],[!Ymin!,!Ymax!])" "!INPUT_LAZ!" "!OUTPUT_LAZ!" filters.crop
					echo rognage dalle voisine qui sortira !OUTPUT_LAZ!
					) else (
					echo Dalle voisine deja rognee: !OUTPUT_LAZ!
					)

                )
				echo fin rognage dalles voisines
		)
		
		)
	)
)




rem ------ Fusion des dalles voisines rognées avec dalle centrale -------
echo début fusion
rem echo %%A
rem pdal merge outputdalle1.laz outputdalle2.laz outputdalle3.laz outputdalle4.laz outputdalle5.laz outputdalle6.laz outputdalle7.laz outputdalle8.laz !ligneMin! merged_output.laz
set FILES=
    
for %%D in (1 2 3 4 5 6 7 8) do (
    if exist D!numDalle!outputdalle%%D.laz (
        set FILES=!FILES! D!numDalle!outputdalle%%D.laz
    )
)

echo Fusion de!FILES! avec la dalle centrale numero !numDalle! 

	
if not "!FILES!"=="" (
	if not exist D!numDalle!merged_output.laz (
    pdal merge %%A !FILES! D!numDalle!merged_output.laz
) 
)


rem a commenter pour gagner du temps 
rem suppression des rognages séparés des dalles voisines
for %%D in (1 2 3 4 5 6 7 8) do (
	if exist D!numDalle!outputdalle%%D.laz (
        del D!numDalle!outputdalle%%D.laz
    )


)

echo fin fusion





rem ------ Création des MNT -------

rem pour l'instant que classe 2, le reste génère des trous
echo Creation du MNT de la dalle !numDalle! 
rem if not exist D!numDalle!MNT.tif (
rem fonctionne aussi mais laisse les trous, pas optimal
rem pdal translate -i D!numDalle!merged_output.laz -o D!numDalle!MNT.tif --writers.gdal.resolution=0.5 -f range --filters.range.limits="Classification[1:1],Classification[2:2],Classification[6:6],Classification[66:66],Classification[67:67],Classification[9:9]"  -f delaunay
rem utilisation de l'outil "conversion de nuage de points - exporter vers un raster (en utilisant la triangulation) de QGIS
rem set PATH=C:\OSGeo4W\apps\qgis-ltr\bin;C:\OSGeo4W\bin;%PATH%
rem "\OSGeo4W\apps\qgis-ltr\pdal_wrench.exe" to_raster_tin --input=D1merged_output.laz --output=D1MNT.tif --resolution=0.5 --tile-size=1000 --filter="Classification == 1 || Classification == 2 || Classification == 6 || Classification == 66 || Classification == 67 || Classification == 9" --threads=24
\OSGeo4W\apps\qgis-ltr\bin\qgis_process.exe run pdal:exportrastertin --INPUT=D!numDalle!merged_output.laz --OUTPUT=MNT.tif --RESOLUTION=0.5 --FILTER_EXPRESSION="Classification = 2 OR Classification = 6 OR Classification =66 OR Classification =67 OR Classification =9"
rem )
	
echo fin creation MNT


rem ------ Création de la carte de densité -------

echo Creation de la carte de densité de la dalle !numDalle! 
\OSGeo4W\apps\qgis-ltr\bin\qgis_process.exe run pdal:density --INPUT=D!numDalle!merged_output.laz --OUTPUT=densite.tif --RESOLUTION=1 --TILE_SIZE=1000 --FILTER_EXPRESSION="Classification = 2 OR Classification = 6 OR Classification = 66 OR Classification = 67 OR Classification = 9"
echo fin de la carte de densité

del D!numDalle!merged_output.laz

rem -------------- Visualisation du relief --------------



rem ------ Création des MDH (Multiple Directions Hillshades) -------

echo Creation du MDH de la dalle !numDalle! 
if not exist D!numDalle!hillshade.tif (
rem qgis_process.exe run rvt:rvt_multi_hillshade --DEM="D!numDalle!MNT.tif" --OUTPUT="D!numDalle!hillshade.tif"
\OSGeo4W\apps\qgis-ltr\bin\qgis_process.exe run rvt:rvt_multi_hillshade --INPUT="MNT.tif" --OUTPUT="D!numDalle!hillshade.tif" --NUM_DIRECTIONS=16 --SAVE_AS_8BIT=True --SUN_ELEVATION=35 --VE_FACTOR=1

)
echo fin MDH

rem ------ Création des SVF (RVT Sky-view factor) -------

echo Creation du SVF de la dalle !numDalle! 
if not exist D!numDalle!SVF.tif (
\OSGeo4W\apps\qgis-ltr\bin\qgis_process.exe run rvt:rvt_svf --INPUT="MNT.tif" --OUTPUT="D!numDalle!SVF.tif" --NOISE_REMOVE=0 --NUM_DIRECTIONS=16 --RADIUS=10 --SAVE_AS_8BIT=True --VE_FACTOR=1

)
echo fin SVF

rem ------ Création des SLO (RVT Slope) -------

echo Creation du SLO de la dalle !numDalle! 
if not exist D!numDalle!Slope.tif (
\OSGeo4W\apps\qgis-ltr\bin\qgis_process.exe run rvt:rvt_slope --INPUT="MNT.tif" --OUTPUT="D!numDalle!Slope.tif" --SAVE_AS_8BIT=True --UNIT=0 --VE_FACTOR=1

)
echo fin SLO

rem ------ Création des LDO (RVT Local Dominance) -------

echo Creation du LDO de la dalle !numDalle! 
if not exist D!numDalle!LDO.tif (
\OSGeo4W\apps\qgis-ltr\bin\qgis_process.exe run rvt:rvt_ld --INPUT="MNT.tif" --OUTPUT="D!numDalle!LDO.tif" --SAVE_AS_8BIT=True --ANGULAR_RES=15 --MIN_RADIUS=10 --MAX_RADIUS=20 --OBSERVER_H=1.7 --VE_FACTOR=1

)
echo fin LDO




echo début rognage final
rem ------ Rognage pour revenir au dimensions de la dalle initiale -------	
	
rem echo !voisinX! et !voisinY!

set /a "Xr=1!voisinX!-10000-1"
set "Xr=0000!Xr!" 
set "Xminr=!Xr:~-4!000"


set /a "Xr2=1!voisinX!-10000"
set "Xr2=0000!Xr2!" 
set "Xmaxr=!Xr2:~-4!000"


set /a "Yr=1!voisinY!-10000-2"
set "Yr=0000!Yr!" 
set "Yminr=!Yr:~-4!000"


set /a "Yr2=1!voisinY!-10000-1"
set "Yr2=0000!Yr2!" 
set "Ymaxr=!Yr2:~-4!000"



set "OUTDIR=Output"
if not exist "!OUTDIR!" (
    mkdir "!OUTDIR!"
)



rem echo !Xminr! et !Xmaxr! et !Yminr! et !Ymaxr!
if not exist "!OUTDIR!\LHD_FXX_!X!_!Y!_MNT_A_0M50_LAMB93_IGN69.tif" (
gdalwarp -te !Xminr! !Yminr! !Xmaxr! !Ymaxr! MNT.tif "!OUTDIR!\LHD_FXX_!X!_!Y!_MNT_A_0M50_LAMB93_IGN69.tif" -of GTiff
)
if not exist "!OUTDIR!\LHD_FXX_!X!_!Y!_MDH_A_LAMB93.tif" (
gdalwarp -te !Xminr! !Yminr! !Xmaxr! !Ymaxr! D!numDalle!hillshade.tif "!OUTDIR!\LHD_FXX_!X!_!Y!_MDH_A_LAMB93.tif" -of GTiff
)
rem if not exist "!OUTDIR!\LHD_FXX_!X!_!Y!_MDH_A_LAMB93_IGN69.tif" (
rem gdalwarp -te !Xminr! !Yminr! !Xmaxr! !Ymaxr! D!numDalle!hillshadeFinal.tif "!OUTDIR!\LHD_FXX_!X!_!Y!_MDH_A_LAMB93.tif" -of GTiff
rem )
if not exist "!OUTDIR!\LHD_FXX_!X!_!Y!_SVF_A_LAMB93.tif" (
gdalwarp -te !Xminr! !Yminr! !Xmaxr! !Ymaxr! D!numDalle!SVF.tif "!OUTDIR!\LHD_FXX_!X!_!Y!_SVF_A_LAMB93.tif" -of GTiff
)
if not exist "!OUTDIR!\LHD_FXX_!X!_!Y!_SLO_A_LAMB93.tif" (
gdalwarp -te !Xminr! !Yminr! !Xmaxr! !Ymaxr! D!numDalle!Slope.tif "!OUTDIR!\LHD_FXX_!X!_!Y!_SLO_A_LAMB93.tif" -of GTiff
)
if not exist "!OUTDIR!\LHD_FXX_!X!_!Y!_LDO_A_LAMB93.tif" (
gdalwarp -te !Xminr! !Yminr! !Xmaxr! !Ymaxr! D!numDalle!LDO.tif "!OUTDIR!\LHD_FXX_!X!_!Y!_LDO_A_LAMB93.tif" -of GTiff
)
if not exist "!OUTDIR!\LHD_FXX_!X!_!Y!_densite_A_LAMB93.tif" (
gdalwarp -te !Xminr! !Yminr! !Xmaxr! !Ymaxr! densite.tif "!OUTDIR!\LHD_FXX_!X!_!Y!_densite_A_LAMB93.tif" -of GTiff
)
	
echo fin rognage final
echo début suppression fichiers non voulus	

rem del D!numDalle!MNT.tif
rem del D!numDalle!MNT.tif.aux.xml

del D!numDalle!hillshade.tif

rem del D!numDalle!hillshadeFinal.tif

del D!numDalle!SVF.tif

del D!numDalle!Slope.tif

del D!numDalle!LDO.tif

rem del D!numDalle!MNS.tif.aux.xml
echo fin suppression







	
	)

)



pause
endlocal
exit /b 0