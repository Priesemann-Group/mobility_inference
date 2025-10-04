
library(sp)
library(RColorBrewer)
library(tidyverse)
library(ggplot2)
library(giscoR)
library(ggiraph)
library(readxl)
library(ggokabeito)
library(ggpubr)
library(wesanderson)
library(leaps)

#Postprocessing 

#model <- "counties"

#consideredwave <- "firstwave"

#run <- "2025-05-01_fourhundred_hierarchicalweight_no2024"

#whattoplot <- "d_C"
#whattoplot <- "exponential"
#whattoplot <- "yaxis_intercept"
#whattoplot <- "slope"
#whattoplot <- "shareLocalIncidence"


if(model == "fedStates"){
  counties <-  c("Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
  "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
  "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
  "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
}else if(model == "counties"){
  # counties <- c("Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",
  #       "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",
  #       "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",
  #       "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",
  #       "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",
  #       "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",
  #       "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",
  #       "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",
  #       "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",
  #       "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",
  #       "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",
  #       "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
  #       "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
  #                "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",
  #                "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn",
  #                "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
  #                "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
  #                "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
  #                "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken")
  # counties <- c("Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
  # "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg",                    "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
  # "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
  # "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
  # "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt", "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
  # "Tuttlingen",  "Ulm",  "Waldshut ", 
  # "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
  # "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis")
  # counties <- c("Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
  #               "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
  #               "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
  #               "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
  #               "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
  #               "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
  #               "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
  #               "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
  #               "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
  #               "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
  #               "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
  #               "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
  #               "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
  #               "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
  #               "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
  #               "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
  #               "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
  #               "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
  #               "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
  #               "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
  #               "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
  #               "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
  #               "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
  #               "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
  #               "Tuttlingen",  "Ulm",  "Waldshut ", 
  #               "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
  #               "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
  #               "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
  #               "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
  #               "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
  #               "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
  #               "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
  #               "Gera",  "Görlitz", "Gotha",  "Greiz",                           
  #               "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
  #               "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
  #               "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
  #               "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
  #               "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
  #               "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
  #               "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
  #               "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
  #               "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
  #               "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
  #               "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
  #               "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
  #               "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
  #               "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
  #               "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
  #               "Weimarer Land",   "Wittenberg",  "Zwickau")
  counties <- c("Ahrweiler", "Aichach-Friedberg", "Alb-Donau-Kreis", "Altenburger Land", "Altenkirchen", "Altmarkkreis Salzwedel", "Altötting", "Alzey-Worms", "Amberg", "Amberg-Sulzbach", "Ammerland", "Anhalt-Bitterfeld", "Ansbach", "Aschaffenburg", "Augsburg", "Aurich", 
               "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach", "Bad Tölz-Wolfratshausen", "Baden-Baden", "Bamberg", "Barnim", "Bautzen", "Bayreuth", "Berchtesgadener Land", "Bergstraße", "Berlin", "Bernkastel-Wittlich", "Biberach", "Bielefeld", "Birkenfeld", "Böblingen", "Bochum", "Bodenseekreis", "Bonn", "Börde", "Borken", "Bottrop", "Brandenburg an der Havel", "Braunschweig", "Breisgau-Hochschwarzwald", "Bremen", "Bremerhaven", "Burgenlandkreis", 
               "Calw", "Celle", "Cham", "Chemnitz", "Cloppenburg", "Coburg", "Cochem-Zell", "Coesfeld", "Cottbus - Chóśebuz", "Cuxhaven", 
               "Dachau", "Dahme-Spreewald", "Darmstadt", "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst", "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau", "Dingolfing-Landau", "Dithmarschen", "Donau-Ries", "Donnersbergkreis", "Dortmund", "Dresden", "Duisburg", "Düren", "Düsseldorf", 
               "Ebersberg", "Eichsfeld", "Eichstätt", "Eifelkreis Bitburg-Prüm", "Elbe-Elster", "Emden", "Emmendingen", "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis", "Erding", "Erfurt", "Erlangen", "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen", "Esslingen", "Euskirchen", 
               "Flensburg", "Forchheim", "Frankenthal (Pfalz)", "Frankfurt (Oder)", "Frankfurt am Main", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Friesland", "Fulda", "Fürstenfeldbruck", "Fürth", 
               "Garmisch-Partenkirchen", "Gelsenkirchen", "Gera", "Germersheim", "Gießen", "Gifhorn", "Göppingen", "Görlitz", "Goslar", "Gotha", "Göttingen", "Grafschaft Bentheim", "Greiz", "Groß-Gerau", "Günzburg", "Gütersloh", 
               "Hagen", "Halle (Saale)", "Hamburg", "Hameln-Pyrmont", "Hamm", "Hannover", "Harburg", "Harz", "Haßberge", "Havelland", "Heidekreis", "Heidelberg", "Heidenheim", "Heilbronn", "Heinsberg", "Helmstedt", "Herford", "Herne", "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildburghausen", "Hildesheim", "Hochsauerlandkreis", "Hochtaunuskreis", "Hof", "Hohenlohekreis", "Holzminden", "Höxter", 
               "Ilm-Kreis", "Ingolstadt", 
               "Jena", "Jerichower Land", 
               "Kaiserslautern", "Karlsruhe", "Kassel", "Kaufbeuren", "Kelheim", "Kempten (Allgäu)", "Kiel", "Kitzingen", "Kleve", "Koblenz", "Köln", "Konstanz", "Krefeld", "Kronach", "Kulmbach", "Kusel", "Kyffhäuserkreis", 
               "Lahn-Dill-Kreis", "Landau in der Pfalz", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Augsburg", "Landkreis Bamberg", "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Heilbronn", "Landkreis Hof", "Landkreis Kaiserslautern", "Landkreis Karlsruhe", "Landkreis Kassel", "Landkreis Landshut", "Landkreis Leipzig", "Landkreis München", "Landkreis Oldenburg", "Landkreis Osnabrück", "Landkreis Passau", "Landkreis Regensburg", "Landkreis Rosenheim", "Landkreis Rostock", "Landkreis Schweinfurt", "Landkreis Würzburg", "Landsberg am Lech", "Landshut", "Leer", "Leipzig", "Leverkusen", "Lichtenfels", "Limburg-Weilburg", "Lindau", "Lippe", "Lörrach", "Lübeck", "Lüchow-Dannenberg", "Ludwigsburg", "Ludwigshafen am Rhein", "Ludwigslust-Parchim", "Lüneburg", 
               "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart", "Main-Tauber-Kreis", "Main-Taunus-Kreis", "Mainz", "Mainz-Bingen", "Mannheim", "Mansfeld-Südharz", "Marburg-Biedenkopf", "Märkisch-Oderland", "Märkischer Kreis", "Mayen-Koblenz", "Mecklenburgische Seenplatte", "Meißen", "Memmingen", "Merzig-Wadern", "Mettmann", "Miesbach", "Miltenberg", "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach", "Mühldorf am Inn", "Mülheim an der Ruhr", "München", "Münster", 
               "Neckar-Odenwald-Kreis", "Neu-Ulm", "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neustadt an der Weinstraße", "Neuwied", "Nienburg/Weser", "Nordfriesland", "Nordhausen", "Nordsachsen", "Nordwestmecklenburg", "Northeim", "Nürnberg", "Nürnberger Land", 
               "Oberallgäu", "Oberbergischer Kreis", "Oberhausen", "Oberhavel", "Oberspreewald-Lausitz", "Odenwaldkreis", "Oder-Spree", "Offenbach", "Offenbach am Main", "Oldenburg", "Olpe", "Ortenaukreis", "Osnabrück", "Ostalbkreis", "Ostallgäu", "Osterholz", "Ostholstein", "Ostprignitz-Ruppin", 
               "Paderborn", "Passau", "Peine", "Pfaffenhofen an der Ilm", "Pforzheim", "Pinneberg", "Pirmasens", "Plön", "Potsdam", "Potsdam-Mittelmark", "Prignitz", 
               "Rastatt", "Ravensburg", "Recklinghausen", "Regen", "Regensburg", "Regionalverband Saarbrücken", "Rems-Murr-Kreis", "Remscheid", "Rendsburg-Eckernförde", "Reutlingen", "Rhein-Erft-Kreis", "Rhein-Hunsrück-Kreis", "Rhein-Lahn-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss", "Rhein-Pfalz-Kreis", "Rhein-Sieg-Kreis", "Rheingau-Taunus-Kreis", "Rheinisch-Bergischer Kreis", "Rhön-Grabfeld", "Rosenheim", "Rostock", "Rotenburg (Wümme)", "Roth", "Rottal-Inn", "Rottweil", 
               "Saale-Holzland-Kreis", "Saale-Orla-Kreis", "Saalekreis", "Saalfeld-Rudolstadt", "Saarlouis", "Saarpfalz-Kreis", "Sächsische Schweiz-Osterzgebirge", "Salzgitter", "Salzlandkreis", "Schaumburg", "Schleswig-Flensburg", "Schmalkalden-Meiningen", "Schwabach", "Schwäbisch Hall", "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis", "Schweinfurt", "Schwerin", "Segeberg", "Siegen-Wittgenstein", "Sigmaringen", "Soest", "Solingen", "Sömmerda", "Sonneberg", "Speyer", "Spree-Neiße", "St. Wendel", "Stade", "Städteregion Aachen", "Starnberg", "Steinburg", "Steinfurt", "Stendal", "Stormarn", "Straubing", "Straubing-Bogen", "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Suhl", 
               "Teltow-Fläming", "Tirschenreuth", "Traunstein", "Trier", "Trier-Saarburg", "Tübingen", "Tuttlingen", 
               "Uckermark", "Uelzen", "Ulm", "Unna", "Unstrut-Hainich-Kreis", "Unterallgäu", 
               "Vechta", "Verden", "Viersen", "Vogelsbergkreis", "Vogtlandkreis", "Vorpommern-Greifswald", "Vorpommern-Rügen", "Vulkaneifel", 
               "Waldeck-Frankenberg", "Waldshut", "Warendorf", "Wartburgkreis", "Weiden in der Oberpfalz", "Weilheim-Schongau", "Weimar", "Weimarer Land", "Weißenburg-Gunzenhausen", "Werra-Meißner-Kreis", "Wesel", "Wesermarsch", "Westerwaldkreis", "Wetteraukreis", "Wiesbaden", "Wilhelmshaven", "Wittenberg", "Wittmund", "Wolfenbüttel", "Wolfsburg", "Worms", "Wunsiedel im Fichtelgebirge", "Wuppertal", "Würzburg", 
               "Zollernalbkreis", "Zweibrücken", "Zwickau")
}
  
counties <- as.data.frame(counties)
colnames(counties) <- c("LK_Name")
counties <- counties %>% mutate(index = row_number() - 1)

if(whattoplot == "d_C"){
  disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/d_C.csv"))
  disFac_post <- disFac_post %>% mutate(index = ceiling(seq_len(nrow(disFac_post)) / 52)-1)
}else if(whattoplot == "exponential"){
  multdisFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/multiplicator_C.csv"))
  colnames(multdisFac_post) <- c("index", "yaxis_intercept")
  slopedisFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/slope_C.csv"))
  colnames(slopedisFac_post) <- c("index", "slope")
  multdisFac_post <- left_join(multdisFac_post, slopedisFac_post)
  disFac_post <-  multdisFac_post %>%
    rowwise() %>%
    mutate(value = {
      integrand <- function(x) {yaxis_intercept * exp(-x/slope)}
      integrate(integrand, lower = 0, upper = 51)$value
    }) %>%
    ungroup()
}else if(whattoplot == "yaxis_intercept"){
  disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/multiplicator_C.csv"))
  colnames(disFac_post) <- c("index", "value")
}else if(whattoplot == "slope"){
  disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/slope_C.csv"))
  colnames(disFac_post) <- c("index", "value")
}else if(whattoplot == "shareLocalIncidence"){
  disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/incidenceweight.csv"))
  colnames(disFac_post) <- c("index", "value")
}

disFac_post <- left_join(disFac_post, counties)

if(model == "counties"){
  #Groups from https://www.bbsr.bund.de/BBSR/DE/forschung/raumbeobachtung/Raumabgrenzungen/deutschland/kreise/siedlungsstrukturelle-kreistypen/kreistypen.html
  LKType <- read_xlsx("/Users/sydney/Downloads/raumgliederungen-referenzen-2023.xlsx", sheet = 4)
  LKType <- LKType %>% mutate(KRS_NAME = case_when(KRS_NAME == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
                                                    KRS_NAME == "Augsburg" ~ "Landkreis Augsburg",
                                                    KRS_NAME == "Leipzig" ~ "Landkreis Leipzig",
                                                    KRS_NAME == "Schweinfurt" ~ "Landkreis Schweinfurt",
                                                    KRS_NAME == "Würzburg" ~ "Landkreis Würzburg",
                                                    KRS_NAME == "Ansbach" ~ "Landkreis Ansbach",
                                                    KRS_NAME == "Aschaffenburg" ~ "Landkreis Aschaffenburg",
                                                    KRS_NAME == "Bamberg" ~ "Landkreis Bamberg",
                                                    KRS_NAME == "Bayreuth" ~ "Landkreis Bayreuth",
                                                    KRS_NAME == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
                                                    KRS_NAME == "Oldenburg (Oldenburg), Stadt" ~ "Oldenburg",
                                                    KRS_NAME == "Coburg" ~ "Landkreis Coburg",
                                                    KRS_NAME == "Fürth" ~ "Landkreis Fürth",
                                                    KRS_NAME == "Heilbronn" ~ "Landkreis Heilbronn",
                                                    KRS_NAME == "Hof" ~ "Landkreis Hof",
                                                    KRS_NAME == "Karlsruhe" ~ "Landkreis Karlsruhe",
                                                    KRS_NAME == "Landshut" ~ "Landkreis Landshut",
                                                    KRS_NAME == "München" ~ "Landkreis München",
                                                   KRS_NAME == "Oldenburg" ~ "Landkreis Oldenburg",
                                                   KRS_NAME == "Osnabrück" ~ "Landkreis Osnabrück",
                                                   KRS_NAME == "Passau" ~ "Landkreis Passau",
                                                   KRS_NAME == "Regensburg" ~ "Landkreis Regensburg",
                                                   KRS_NAME == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                                                   KRS_NAME == "Frankenthal (Pfalz), kreisfreie Stadt" ~ "Frankenthal (Pfalz)",
                                                   KRS_NAME == "Region Hannover" ~ "Hannover",
                                                   KRS_NAME == "Lübeck, Hansestadt" ~ "Lübeck",
                                                   KRS_NAME == "Koblenz, kreisfreie Stadt" ~ "Koblenz",
                                                   KRS_NAME == "Mainz, kreisfreie Stadt" ~ "Mainz",
                                                   KRS_NAME == "Mühldorf a.Inn" ~ "Mühldorf",
                                                   KRS_NAME == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
                                                   KRS_NAME == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                                                   KRS_NAME == "Neustadt a.d.Waldnaab" ~ "Neustadt an der Waldnaab",
                                                   KRS_NAME == "Neustadt an der Weinstraße, kreisfreie Stadt" ~ "Neustadt an der Weinstraße",
                                                   KRS_NAME == "Nienburg (Weser)" ~ "NienburgWeser",
                                                   KRS_NAME == "Pirmasens, kreisfreie Stadt" ~ "Pirmasens",
                                                   KRS_NAME == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                                                   KRS_NAME == "Speyer, kreisfreie Stadt" ~ "Speyer",
                                                   KRS_NAME == "Trier, kreisfreie Stadt" ~ "Trier",
                                                   KRS_NAME == "Waldshut" ~ "Waldshut ",
                                                   KRS_NAME == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz",
                                                   KRS_NAME == "Worms, kreisfreie Stadt" ~ "Worms",
                                                   KRS_NAME == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                                   KRS_NAME == "Zweibrücken, kreisfreie Stadt" ~ "Zweibrücken",
                                                   KRS_NAME == "Landau in der Pfalz, kreisfreie Stadt" ~ "Landau in der Pfalz",
                                                   .default = KRS_NAME))
  LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Stadt$", "")
  LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Stadtkreis$", "")
  LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Landeshauptstadt$", "")
  LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Freie und Hansestadt$", "")
  GrosseGrossstadt <- LKType %>% filter(KTD_NAME == "Große kreisfreie Großstadt")
  KleineGrossstadt <- LKType %>% filter(KTD_NAME == "Kleine kreisfreie Großstadt")
  StaedtischerKreis <- LKType %>% filter(KTD_NAME == "Städtischer Kreis")
  LaendlicherKreis <- LKType %>% filter(KTD_NAME == "Dünn besiedelter ländlicher Kreis")
  Verdichtungsansatz <- LKType %>% filter(KTD_NAME == "Ländlicher Kreis mit Verdichtungsansätzen")
  
  SchleswigHolstein <- LKType %>% filter(BLD_NAME == "Schleswig-Holstein")
  Hamburg <- LKType %>% filter(BLD_NAME == "Hamburg")
  Niedersachsen <- LKType %>% filter(BLD_NAME == "Niedersachsen")
  Bremen <- LKType %>% filter(BLD_NAME == "Bremen")
  NordrheinWestfalen <- LKType %>% filter(BLD_NAME == "Nordrhein-Westfalen")
  Hessen <- LKType %>% filter(BLD_NAME == "Hessen")
  RheinlandPfalz <- LKType %>% filter(BLD_NAME == "Rheinland-Pfalz")
  BadenWuerttemberg <- LKType %>% filter(BLD_NAME == "Baden-Württemberg")
  Bayern <- LKType %>% filter(BLD_NAME == "Bayern")
  Saarland <- LKType %>% filter(BLD_NAME == "Saarland")
  Berlin <- LKType %>% filter(BLD_NAME == "Berlin")
  Brandenburg <- LKType %>% filter(BLD_NAME == "Brandenburg")
  MecklenburgVorpommern <- LKType %>% filter(BLD_NAME == "Mecklenburg-Vorpommern")
  Sachsen <- LKType %>% filter(BLD_NAME == "Sachsen")
  SachsenAnhalt <- LKType %>% filter(BLD_NAME == "Sachsen-Anhalt")
  Thueringen <- LKType %>% filter(BLD_NAME == "Thüringen")

  disFac_post <- disFac_post %>% mutate(group = case_when(
                           LK_Name %in% GrosseGrossstadt$KRS_NAME ~ "Grosse Grossstadt",
                           LK_Name %in% KleineGrossstadt$KRS_NAME ~ "Kleine Grossstadt",
                           LK_Name %in% LaendlicherKreis$KRS_NAME ~ "Dünn besiedelt ländlicher Kreis",
                           LK_Name %in% StaedtischerKreis$KRS_NAME ~ "Städtische Kreise",
                           LK_Name %in% Verdichtungsansatz$KRS_NAME ~ "Ländlicher Kreis mit Verdichtungsansätzen")) %>%
                           mutate(fedState = case_when(LK_Name %in% SchleswigHolstein$KRS_NAME~ "Schleswig-Holstein",
                                  LK_Name %in% Hamburg$KRS_NAME ~ "Hamburg",
                                  LK_Name %in% Niedersachsen$KRS_NAME ~ "Niedersachsen",
                                  LK_Name %in% NordrheinWestfalen$KRS_NAME ~ "Nordrhein-Westfalen",
                                  LK_Name %in% Bremen$KRS_NAME ~ "Bremen",
                                  LK_Name %in% Bayern$KRS_NAME ~ "Bayern",
                                  LK_Name %in% BadenWuerttemberg$KRS_NAME ~ "Baden-Württemberg",
                                  LK_Name %in% Berlin$KRS_NAME ~ "Berlin",
                                  LK_Name %in% Brandenburg$KRS_NAME ~ "Brandenburg",
                                  LK_Name %in% Sachsen$KRS_NAME ~ "Sachsen",
                                  LK_Name %in% SachsenAnhalt$KRS_NAME ~ "Sachsen-Anhalt",
                                  LK_Name %in% Thueringen$KRS_NAME ~ "Thüringen",
                                  LK_Name %in% Saarland$KRS_NAME ~ "Saarland",
                                  LK_Name %in% MecklenburgVorpommern$KRS_NAME ~ "Mecklenburg-Vorpommern",
                                  LK_Name %in% RheinlandPfalz$KRS_NAME ~ "Rheinland-Pfalz",
                                  LK_Name %in% Hessen$KRS_NAME ~ "Hessen")) %>%
                            mutate(group_eng = case_when(group == "Stadtstaat" ~ "City State",
                                                         group == "Grosse Grossstadt" ~ "Large City",
                                                         group == "Kleine Grossstadt" ~ "Small City",
                                                         group == "Städtische Kreise" ~ "Suburban/Independent Town",
                                                         group == "Ländlicher Kreis mit Verdichtungsansätzen" ~ "Medium Rural",
                                                         group == "Dünn besiedelt ländlicher Kreis" ~ "Rural"))

}

if(whattoplot %in% c("d_C")){
dates <- seq(as.Date("2020-03-08"),  as.Date("2021-02-28"), by = "week")
#dates2024 <- seq(as.Date("2024-01-07"),  as.Date("2024-12-31"), by = "week")
#dates <- append(dates, dates2024)
dates <- rep(unique(dates), times = length(unique(disFac_post$LK_Name)))
disFac_post <- cbind(disFac_post, dates)
disFac_post$date <- as.Date(disFac_post$date)
}

if(model == "fedStates"){
colnames(disFac_post) <- c("rowNo", "diseaseFactor", "LK_no", "LK_Name", "date")
}else if(model == "counties"){
  if(whattoplot %in% c("d_C")){
  colnames(disFac_post) <- c("rowNo", "diseaseFactor", "LK_no", "LK_Name", "group", "fedState", "group_eng", "date", "date2")
  }
}

#Colored by LK_Name
# ggplot(disFac_post %>% filter(date < as.Date("2021-03-01")), aes(x=date, y = diseaseFactor, color=LK_Name)) +
#   geom_line() +
#   theme_minimal()+
#   theme(text = element_text(size = 35)) +
#   theme(legend.position = "bottom", legend.title = element_blank()) +
#   theme(axis.ticks.x = element_line(),
#         axis.ticks.y = element_line(),
#         axis.ticks.length = unit(10, "pt")) +
#   scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "2 month"), date_labels = "%m/%Y") +
#   ylab("Disease Factor") +
#   xlab("Date")+
#   guides(color=guide_legend(nrow=8,byrow=TRUE))

#Colored by group 
# ggplot(disFac_post %>% filter(date < "2022-01-01"), aes(x=date, y = diseaseFactor, color=group)) +
#   geom_point() +
#   theme_minimal()+
#   theme(text = element_text(size = 35)) +
#   theme(legend.position = "bottom", legend.title = element_blank()) +
#   theme(axis.ticks.x = element_line(),
#         axis.ticks.y = element_line(),
#         axis.ticks.length = unit(10, "pt")) +
#   scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "2 month"), date_labels = "%m/%Y") +
#   ylab("Disease Factor") +
#   xlab("Date")+
#   guides(color=guide_legend(nrow=5,byrow=TRUE))

#ggsave("LargeModel.pdf", dpi = 500, w = 18, h = 12)

#Line by group
# disFac_post_groups <- disFac_post %>% group_by(group, date) %>% summarise(lowerperc = quantile(diseaseFactor, 0.025), upperperc = quantile(diseaseFactor, 0.975), diseaseFactor = mean(diseaseFactor))
# 
# ggplot(disFac_post_groups %>% filter(date < "2022-01-01") %>% filter(!is.na(group)), aes(x=date, y = diseaseFactor, fill = group)) +
#   geom_line(aes(color=group), size = 2) +
#   #geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), alpha = 0.2) +
#   theme_minimal()+
#   theme(text = element_text(size = 35)) +
#   #scale_color_brewer(palette = "RdBu") +
#   #scale_fill_brewer(palette = "RdBu") +
#   theme(legend.position = "bottom", legend.title = element_blank()) +
#   theme(axis.ticks.x = element_line(),
#         axis.ticks.y = element_line(),
#         axis.ticks.length = unit(10, "pt")) +
#   scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "2 month"), date_labels = "%m/%y") +
#   ylab("Disease Factor") +
#   xlab("Date")+
#   guides(color=guide_legend(nrow=5,byrow=TRUE))

#ggsave("DiseaseFactorFirst.png", dpi = 500, w = 12, h = 9)

# Spatial Plot ------------------------------------------------------------

if(whattoplot == "d_C"){
if(consideredwave == "firstwave"){
min_first_wave <- disFac_post %>% filter(date < "2020-07-01") %>% 
  group_by(LK_Name) %>% slice_min(diseaseFactor) 
min_first_wave <- min_first_wave[order(min_first_wave$date),]
colnames(min_first_wave)[2] <- "value"
valuetoplot <- min_first_wave
}else if(consideredwabe == "secondwave"){
min_second_wave <- disFac_post %>% filter(date > "2020-07-01") %>% 
  filter(date < "2021-03-01") %>% 
  group_by(LK_Name) %>% slice_min(diseaseFactor) 
min_second_wave <- min_second_wave[order(min_second_wave$date),]
colnames(min_second_wave)[2] <- "value"
valuetoplot <- min_second_wave
}
}else if(whattoplot %in% c("exponential", "yaxis_intercept", "slope", "shareLocalIncidence")){
valuetoplot <- disFac_post
}

if(model == "fedStates"){
  germany_districts <- gisco_get_nuts(
    year = "2021", 
    nuts_level = 1,
    epsg = 3035,
    country = 'Germany'
  ) %>% # Nicer output
  as_tibble() %>% 
    janitor::clean_names() %>% dplyr::rowwise() %>%
    mutate(name_latn = str_split(name_latn, ",")[[1]][1]) %>%
    left_join(min_first_wave, by = join_by(name_latn == LK_Name)) %>%
    mutate(diseaseFactor = case_when(nuts_name == "Leipzig" ~ NA, .default = diseaseFactor))
}else if(model == "counties"){
  germany_districts <- gisco_get_nuts(
    year = "2021", 
    nuts_level = 3,
    epsg = 3035,
    country = 'Germany',
    cache = TRUE,
    update_cache = TRUE
  ) %>%
    # Nicer output
    as_tibble() %>% 
    mutate(NAME_LATN = case_when(NAME_LATN == "München, Landkreis" ~ "Landkreis München",
                                      NAME_LATN ==  "Karlsruhe, Landkreis" ~ "Landkreis Karlsruhe",
                                      NAME_LATN == "Leipzig" ~ "Landkreis Leipzig",
                                      NAME_LATN == "Oldenburg (Oldenburg), Kreisfreie Stadt" ~ "Oldenburg",
                                      NAME_LATN == "Oldenburg" ~ "Landkreis Oldenburg",
                                      NAME_LATN == "Osnabrück, Landkreis" ~ "Landkreis Osnabrück",
                                      NAME_LATN ==  "Augsburg, Landkreis" ~ "Landkreis Augsburg",
                                      NAME_LATN ==  "Landshut, Landkreis" ~ "Landkreis Landshut",
                                      NAME_LATN ==  "Regensburg, Landkreis" ~ "Landkreis Regensburg",
                                      NAME_LATN ==  "Würzburg, Landkreis" ~ "Landkreis Würzburg",
                                      NAME_LATN ==  "Schweinfurt, Landkreis" ~ "Landkreis Schweinfurt",
                                      NAME_LATN ==  "Passau, Landkreis" ~ "Landkreis Passau",
                                      NAME_LATN ==  "Hof, Landkreis" ~ "Landkreis Hof",
                                      NAME_LATN ==  "Heilbronn, Landkreis" ~ "Landkreis Heilbronn",
                                      NAME_LATN ==  "Fürth, Landkreis" ~ "Landkreis Fürth",
                                      NAME_LATN ==  "Coburg, Landkreis" ~ "Landkreis Coburg",
                                      NAME_LATN ==  "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
                                      NAME_LATN ==  "Bamberg, Landkreis" ~ "Landkreis Bamberg",
                                      NAME_LATN ==  "Ansbach, Landkreis" ~ "Landkreis Ansbach",
                                      NAME_LATN ==  "Region Hannover" ~ "Hannover",
                                      NAME_LATN == "Dillingen a.d. Donau" ~ "Dillingen an der Donau",
                                      NAME_LATN ==  "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
                                      NAME_LATN == "Wunsiedel i. Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                      NAME_LATN == "Neustadt a. d. Waldnaab" ~ "Neustadt an der Waldnaab",
                                      NAME_LATN == "Mühldorf a. Inn" ~ "Mühldorf am Inn",
                                      NAME_LATN == "Weiden i. d. Opf, Kreisfreie Stadt" ~ "Weiden in der Oberpfalz",
                                      NAME_LATN == "Neumarkt i. d. OPf." ~ "Neumarkt in der Oberpfalz",
                                 NAME_LATN == "Neustadt a. d. Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                                 NAME_LATN == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                                 NAME_LATN == "Nienburg (Weser)" ~ "NienburgWeser",
                                      .default = NAME_LATN)) %>%
    janitor::clean_names() %>% dplyr::rowwise() %>%
    mutate(name_latn = str_split(name_latn, ",")[[1]][1]) %>%
    left_join(valuetoplot, by = join_by(name_latn == LK_Name))
}

if(whattoplot == "d_C"){
 title <- "Minimal disease factor"
}else if(whattoplot == "exponential"){
  title <- "Integral of Exponential"
}else if(whattoplot == "yaxis_intercept"){
 title <- "Y-Axis Intercept" 
}else if(whattoplot == "slope"){
  title <- "Timescale"
}else if(whattoplot == "shareLocalIncidence"){
  title <- "Weight of local incidence"
}
  
plot <- germany_districts %>% filter(value < 0.6) %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill = value)) +
  theme_minimal() +
  xlab("") +
  ylab("") +
  scico::scale_fill_scico(palette = "lajolla") +
  geom_sf_interactive(
    fill = NA, 
    aes(
      data_id = nuts_id,
    ),
    linewidth = 0.1
  ) +
  theme(text = element_text(size = 20), axis.text = element_blank(), axis.ticks = element_blank()) +
  guides(fill = guide_colourbar(
    title = title
  )) +
  coord_sf(expand = FALSE) 

#ggsave("GermanyPlotSecond_SecondWave.png", plot, dpi = 500, w = 9, h = 7)  

girafe(ggobj = plot)


# Boxplots ----------------------------------------------------------------

# LK Type -----------------------------------------------------------------

valuetoplot$group <- factor(valuetoplot$group, levels = c("Grosse Grossstadt", "Kleine Grossstadt", "Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
valuetoplot$group_eng <- factor(valuetoplot$group_eng, levels = c("Large City", "Small City", "Suburban/Independent Town", "Medium Rural", "Rural"))

my_comparisons <- list(c("Grosse Grossstadt", "Kleine Grossstadt"),
                       c("Kleine Grossstadt", "Städtische Kreise"),
                       c("Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen"),
                       c("Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
my_comparisons <- list(c("Large City", "Small City"),
                       c("Small City", "Suburban/Independent Town"),
                       c("Suburban/Independent Town", "Medium Rural"),
                       c("Medium Rural", "Rural"))
symnum.args <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, Inf), symbols = c("****", "***", "**", "*", "ns"))

manual_scale <- c("#D4B2CC", "#D385AC",  "#A56693", "#66507A", "#2D204C")

boxplot <- ggplot(valuetoplot %>% filter(!is.na(group_eng)), aes(x= group_eng, y=value)) +
  geom_boxplot(aes(color = group_eng), lwd=1.5)+
  stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "t.test", size = 5) +
  theme_minimal() +
  guides(color=guide_legend(nrow=5,byrow=TRUE)) +
  theme(legend.position = "bottom") +
  ylab("Weight of Local Incidence") +
  scale_color_manual(values= manual_scale) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_text(size = 17),
        axis.title.y=element_text(size = 20),
        legend.title = element_blank(),
        legend.text = element_text(size = 15),
        #axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"), 
        axis.line = element_line()) 


ggplot(valuetoplot) +
  geom_boxplot(aes(y=value, fill = fedState))+
  theme_minimal() +
  theme(legend.position = "bottom") +
  ylab(title) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_text(size = 15),
        axis.title.y=element_text(size = 20),
        legend.title = element_blank(),
        legend.text = element_text(size = 15)) +
  guides(fill=guide_legend(nrow=4,byrow=TRUE))

valuetoplot <- valuetoplot %>% mutate(eastWest = case_when(fedState %in% c("Brandenburg", "Mecklenburg-Vorpommern", "Sachsen", "Sachsen-Anhalt", "Thüringen") ~ "East", .default = "West"))
ggplot(valuetoplot) +
  geom_boxplot(aes(y=value, color = eastWest), lwd=1.5)+
  theme_minimal() +
  theme(legend.position = "bottom") +
  ylab(title) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_text(size = 15),
        axis.title.y=element_text(size = 20),
        legend.title = element_blank(),
        legend.text = element_text(size = 15)) +
  guides(fill=guide_legend(nrow=4,byrow=TRUE))


# Income ------------------------------------------------------------------

# #Prep Income
# #https://www.statistikportal.de/de/vgrdl/ergebnisse-kreisebene/einkommen-kreise
# 
# incomeDf <- read_xlsx("/Users/sydney/Downloads/vgrdl_r2b3_bs2023.xlsx", sheet=13, skip = 4)
# incomeDf <- incomeDf %>% select(Land, Gebietseinheit, `2022`)
# colnames(incomeDf) <- c("fedStateshort", "LK_Name", "IncomePerson2022")
# incomeDf <- incomeDf %>% mutate(LK_Name = case_when(
#   LK_Name == "München, Landkreis" ~ "Landkreis München",
#   LK_Name ==  "Karlsruhe, Landkreis" ~ "Landkreis Karlsruhe",
#   LK_Name == "Leipzig, Landkreis" ~ "Landkreis Leipzig",
#   LK_Name == "Oldenburg (Oldenburg), Kreisfreie Stadt" ~ "Oldenburg",
#   LK_Name == "Oldenburg, Landkreis" ~ "Landkreis Oldenburg",
#   LK_Name == "Osnabrück, Landkreis" ~ "Landkreis Osnabrück",
#   LK_Name ==  "Augsburg, Landkreis" ~ "Landkreis Augsburg",
#   LK_Name ==  "Landshut, Landkreis" ~ "Landkreis Landshut",
#   LK_Name ==  "Rosenheim, Landkreis" ~ "Landkreis Rosenheim",
#   LK_Name ==  "Regensburg, Landkreis" ~ "Landkreis Regensburg",
#   LK_Name ==  "Kaiserslautern, Landkreis" ~ "Landkreis Kaiserslautern",
#   LK_Name ==  "Würzburg, Landkreis" ~ "Landkreis Würzburg",
#   LK_Name ==  "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
#   LK_Name ==  "Schweinfurt, Landkreis" ~ "Landkreis Schweinfurt",
#   LK_Name ==  "Passau, Landkreis" ~ "Landkreis Passau",
#   LK_Name ==  "Hof, Landkreis" ~ "Landkreis Hof",
#   LK_Name ==  "Heilbronn, Landkreis" ~ "Landkreis Heilbronn",
#   LK_Name ==  "Fürth, Landkreis" ~ "Landkreis Fürth",
#   LK_Name ==  "Coburg, Landkreis" ~ "Landkreis Coburg",
#   LK_Name ==  "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
#   LK_Name ==  "Bamberg, Landkreis" ~ "Landkreis Bamberg",
#   LK_Name ==  "Ansbach, Landkreis" ~ "Landkreis Ansbach",
#   LK_Name ==  "Region Hannover, Landkreis" ~ "Hannover",
#   LK_Name == 	"Nienburg (Weser), Landkreis" ~ "NienburgWeser",
#   LK_Name == "Rhein-Kreis Neuss, Kreis" ~ "Rhein-Neuss",
#   LK_Name == "Altenkirchen (Westerwald), Landkreis" ~ "Altenkirchen",
#   LK_Name == "Mühldorf a.Inn, Landkreis" ~ "Mühldorf am Inn",
#   LK_Name == "Neumarkt i.d.OPf., Landkreis" ~ "Neumarkt in der Oberpfalz",
#   LK_Name == "Neustadt a.d.Aisch-Bad Windsheim, Landkreis" ~ "Neustadt an der Aisch-Bad Windsheim",
#   LK_Name ==  "Neustadt a.d.Waldnaab, Landkreis"~"Neustadt an der Waldnaab",
#   LK_Name == "Waldshut, Landkreis" ~ "Waldshut ",
#   LK_Name == "Weiden i.d.OPf., Kreisfreie Stadt" ~ "Weiden in der Oberpfalz",
#   LK_Name == "Wunsiedel i.Fichtelgebirge, Landkreis" ~ "Wunsiedel im Fichtelgebirge",
#   LK_Name == "Dillingen a.d.Donau, Landkreis" ~ "Dillingen an der Donau",
#   LK_Name == "Saarbrücken, Regionalverband" ~ "Regionalverband Saarbrücken",
#   .default = LK_Name
# ))
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Landkreis$", "")
# #incomeDf$LK_Name <- str_replace(LKType$LK_Name, ", Regierungsbezirk$", "")
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Stadtkreis$", "")
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Kreisfreie Stadt$", "")
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Kreis$", "")
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Landeshauptstadt$", "")
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Universitätsstadt$", "")
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Hansestadt, Kreisfreie Stadt$", "")
# incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Hansestadt$", "")
# 
# incomeDf <- incomeDf %>% mutate(discreteIncome = case_when(IncomePerson2022 < 25000 ~ "<25,000",
#                                                            IncomePerson2022 < 30000 ~ "25,000-30,000",
#                                                            IncomePerson2022 < 35000 ~ "30,000-35,000",
#                                                            IncomePerson2022 > 35000 ~ ">35,000"))
# 
# valuetoplot <- left_join(valuetoplot, incomeDf, by = c("LK_Name"))
# 
# valuetoplot$discreteIncome <- factor(valuetoplot$discreteIncome, levels = c("<25,000", "25,000-30,000", "30,000-35,000", ">35,000"))
# 
# my_comparisons <- list(c("25,000-30,000", "<25,000"),
#                        c("30,000-35,000", "25,000-30,000"),
#                        c(">35,000", "30,000-35,000"))
# symnum.args <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, Inf), symbols = c("****", "***", "**", "*", "ns"))
# 
# ggplot(valuetoplot, aes(x=discreteIncome, y=value)) +
#   geom_boxplot(aes(color =discreteIncome), lwd=1.5)+
#   stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "wilcox.test") +
#   theme_minimal() +
#   theme(legend.position = "bottom") +
#   ylab(title) +
#   scale_color_manual(values= wes_palette("Darjeeling1", n = 4)) +
#   theme(axis.title.x=element_blank(),
#         axis.text.x=element_blank(),
#         axis.ticks.x=element_blank(),
#         axis.text.y=element_text(size = 15),
#         axis.title.y=element_text(size = 20),
#         legend.title = element_blank(),
#         legend.text = element_text(size = 15)) +
#   guides(fill=guide_legend(nrow=3,byrow=TRUE))
#                                    
# voterturnout <- read_xlsx("/Users/sydney/Downloads/Deutschlandatlas-Daten.xlsx", sheet = 4)
# voterturnout <- voterturnout %>% mutate(Kreisname = case_when(
#   KRS1221 == "9671000" ~ "Landkreis Aschaffenburg",
#   KRS1221 == "9472000" ~ "Landkreis Bayreuth",
#   KRS1221 == "9679000" ~ "Landkreis Würzburg",
#   KRS1221 == "9571000" ~ "Landkreis Ansbach",
#   KRS1221 == "9471000" ~ "Landkreis Bamberg",
#   KRS1221 == "9473000" ~ "Landkreis Coburg",
#   KRS1221 == "9573000" ~ "Landkreis Fürth",
#   KRS1221 == "9475000" ~ "Landkreis Hof",
#   KRS1221 == "9274000" ~ "Landkreis Landshut",
#   KRS1221 == "9275000" ~ "Landkreis Passau",
#   KRS1221 == "9375000" ~ "Landkreis Regensburg",
#   KRS1221 == "9772000" ~ "Landkreis Augsburg",
#   KRS1221 == "9678000" ~ "Landkreis Schweinfurt",
#   KRS1221 == "9187000" ~ "Landkreis Rosenheim",
#   Kreisname == "Region Hannover" ~ "Hannover",
#   Kreisname == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
#   Kreisname == "Kaiserslautern" ~ "Landkreis Kaiserslautern",
#   Kreisname == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
#   Kreisname == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
#   Kreisname == "Neustadt a.d.Waldnaab" ~ "Neustadt an der Waldnaab",
#   Kreisname == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz", 
#   Kreisname == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
#   Kreisname == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
#   Kreisname == "München" ~ "Landkreis München",
#   Kreisname == "Leipzig" ~ "Landkreis Leipzig",
#   Kreisname == "Oldenburg" ~ "Landkreis Oldenburg",
#   Kreisname == "Oldenburg (Oldenburg), Stadt" ~ "Oldenburg",
#   Kreisname == "Osnabrück" ~ "Landkreis Osnabrück",
#   Kreisname == "Nienburg (Weser)" ~ "NienburgWeser",
#   Kreisname == "Waldshut" ~ "Waldshut ",
#   Kreisname == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
#   Kreisname == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
#   Kreisname == "Heilbronn" ~ "Landkreis Heilbronn",
#   Kreisname == "Karlsruhe" ~ "Landkreis Karlsruhe",
#   .default = Kreisname
# ))
# voterturnout <- voterturnout %>% select(c(Kreisname, wahl_beteil, alq))
# colnames(voterturnout) <- c("LK_Name", "voterTurnout", "unemploymentQuota")
# voterturnout <- voterturnout %>% mutate(voterTurnoutDiscrete = case_when(voterTurnout < 65 ~ "[0%,65%)",
#                                                                          voterTurnout < 70 ~ "[65%,70%)",
#                                                                          voterTurnout < 75 ~ "[70%,75%)",
#                                                                          voterTurnout < 80 ~ "[75%,80%)",
#                                                                          voterTurnout < 85 ~ "[80%,85%)",
#                                                                          .default = "[85%,100%]"))
# voterturnout <- voterturnout %>% mutate(unemploymentQuotaDiscrete = case_when(unemploymentQuota < 3 ~ "[0%,3%)",
#                                                                               unemploymentQuota < 6 ~ "[3%,6%)",
#                                                                               unemploymentQuota < 9 ~ "[6%,9%)",
#                                                                               unemploymentQuota < 100 ~ "[9%,100%)"))
# voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Kreis$", "")
# voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Stadt$", "")
# voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Freie und Hansestadt$", "")
# voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", kreisfreie Stadt$", "")
# voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Landeshauptstadt$", "")
# voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Stadtkreis$", "")
# voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Hansestadt$", "")
# valuetoplot <- left_join(valuetoplot, voterturnout)
# 
# my_comparisons <- list(c("[0%,65%)", "[65%,70%)"), 
#                        c("[65%,70%)", "[70%,75%)"),
#                        c("[70%,75%)", "[75%,80%)"),
#                        c("[75%,80%)", "[80%,85%)"),
#                        c("[80%,85%)", "[85%,100%]"))
# 
# ggplot(valuetoplot, aes(x=voterTurnoutDiscrete, y=value)) +
#   geom_boxplot(aes(color =voterTurnoutDiscrete), lwd=1.5)+
#   stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "wilcox.test") +
#   theme_minimal() +
#   theme(legend.position = "bottom") +
#   ylab(title) +
#   #scale_color_manual(values= wes_palette("Darjeeling1", n = 6)) +
#   theme(axis.title.x=element_blank(),
#         axis.text.x=element_blank(),
#         axis.ticks.x=element_blank(),
#         axis.text.y=element_text(size = 15),
#         axis.title.y=element_text(size = 20),
#         legend.title = element_blank(),
#         legend.text = element_text(size = 15)) +
#   guides(fill=guide_legend(nrow=3,byrow=TRUE))
# 
# my_comparisons <- list(c("[0%,3%)", "[3%,6%)"), 
#                        c("[3%,6%)", "[6%,9%)"),
#                        c("[6%,9%)", "[9%,100%)"))
# 
# ggplot(valuetoplot, aes(x=unemploymentQuotaDiscrete, y=value)) +
#   geom_boxplot(aes(color =unemploymentQuotaDiscrete), lwd=1.5)+
#   stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "wilcox.test") +
#   theme_minimal() +
#   theme(legend.position = "bottom") +
#   ylab(title) +
#   #scale_color_manual(values= wes_palette("Darjeeling1", n = 6)) +
#   theme(axis.title.x=element_blank(),
#         axis.text.x=element_blank(),
#         axis.ticks.x=element_blank(),
#         axis.text.y=element_text(size = 15),
#         axis.title.y=element_text(size = 20),
#         legend.title = element_blank(),
#         legend.text = element_text(size = 15)) +
#   guides(fill=guide_legend(nrow=3,byrow=TRUE))

# MANOVA test
# res.man <- manova(cbind(group_eng, discreteIncome) ~ value, data = valuetoplot)
# summary(res.man)
# summary.aov(res.man)
# 
# #Anova Test (separately for every variable)
# #https://bookdown.org/steve_midway/DAR/understanding-anova-in-r.htm
# 
# #Type of LK
# res.man <- aov(valuetoplot$value ~ valuetoplot$group_eng)
# summary(res.man)
# 
# #Discrete income
# res.man <- aov(valuetoplot$value ~ valuetoplot$discreteIncome)
# summary(res.man)
# 
# #Discrete voter turnout
# res.man <- aov(valuetoplot$value ~ valuetoplot$voterTurnoutDiscrete)
# summary(res.man)
# 
# #Discrete unemyploment rate
# res.man <- aov(valuetoplot$value ~ valuetoplot$unemploymentQuotaDiscrete)
# 
# #Comparison of regression models using anova()
# fit_group <- lm(value ~ group_eng, data = valuetoplot)  
# anova(fit_group)
# #Alternative method: summary(aov(value ~ group_eng, data = valuetoplot))
# fit_income <- lm(value ~ group_eng + discreteIncome, data = valuetoplot)
# anova(fit_income)
# fit_votes <- lm(value ~ group_eng + voterTurnoutDiscrete, data= valuetoplot)
# anova(fit_votes)
# fit_incomevotes <- lm(value ~ group_eng + discreteIncome + voterTurnoutDiscrete, data = valuetoplot)
# anova(fit_incomevotes)
# 
# # Regression Analysis -----------------------------------------------------
# 
# #Population density 
# 
# popDensity <- read_xlsx("/Users/sydney/Downloads/04-kreise.xlsx", sheet = 2, skip = 4)
# colnames(popDensity) <- c("LKNumber", "LKType", "LK_Name", "SomeNumber", "SomeOtherNumber", "Inhabitants", "InhabitantsMale", "InhabitantsFemale", "Inhabitantsperkm2")
# popDensity <- popDensity %>% mutate(LK_Name = case_when((LK_Name == "Augsburg" & LKType == "Landkreis") ~ "Landkreis Augsburg",
# (LK_Name == "Leipzig" & LKType == "Landkreis") ~ "Landkreis Leipzig",
# (LK_Name == "Schweinfurt" & LKType == "Landkreis") ~ "Landkreis Schweinfurt",
# (LK_Name == "Würzburg" & LKType == "Landkreis") ~ "Landkreis Würzburg",
# (LK_Name == "Ansbach" & LKType == "Landkreis") ~ "Landkreis Ansbach",
# (LK_Name =="Aschaffenburg" & LKType == "Landkreis") ~ "Landkreis Aschaffenburg",
# (LK_Name == "Bamberg" & LKType == "Landkreis") ~ "Landkreis Bamberg", 
# (LK_Name == "Bayreuth" & LKType == "Landkreis") ~ "Landkreis Bayreuth",
# (LK_Name == "Kassel" & LKType == "Landkreis") ~ "Landkreis Kassel",
# (LK_Name == "Rosenheim" & LKType == "Landkreis") ~ "Landkreis Rosenheim",
# LK_Name == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
# LK_Name =="Oldenburg (Oldenburg), Stadt" ~ "Oldenburg",
# (LK_Name == "Coburg" & LKType == "Landkreis") ~ "Landkreis Coburg",
# (LK_Name == "Fürth" & LKType == "Landkreis") ~ "Landkreis Fürth",
# (LK_Name == "Heilbronn" & LKType == "Landkreis") ~ "Landkreis Heilbronn",
# (LK_Name == "Hof" & LKType == "Landkreis") ~ "Landkreis Hof",
# (LK_Name == "Karlsruhe" & LKType == "Landkreis") ~ "Landkreis Karlsruhe",
# (LK_Name == "Landshut" & LKType == "Landkreis") ~ "Landkreis Landshut",
# (LK_Name == "München" & LKType == "Landkreis") ~ "Landkreis München",
# (LK_Name == "Oldenburg" & LKType == "Landkreis") ~ "Landkreis Oldenburg",
# (LK_Name == "Osnabrück" & LKType == "Landkreis") ~ "Landkreis Osnabrück",
# (LK_Name == "Passau" & LKType == "Landkreis") ~ "Landkreis Passau",
# (LK_Name == "Regensburg" & LKType == "Landkreis") ~ "Landkreis Regensburg",
# LK_Name == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
# LK_Name == "Kassel, documenta-Stadt" ~ "Kassel",
# LK_Name == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
# LK_Name == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
# LK_Name ==  "Neustadt a.d.Waldnaab" ~ "Neustadt an der Waldnaab",
# LK_Name == "Waldshut" ~ "Waldshut ",
# LK_Name == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz",
# LK_Name == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
# LK_Name == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
# LK_Name == "Saarbrücken, Regionalverband" ~ "Regionalverband Saarbrücken",
# LK_Name == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
# LK_Name =="Nienburg (Weser)" ~ "NienburgWeser",
# LK_Name == "Pirmasens, kreisfreie Stadt" ~ "Pirmasens",
# LK_Name == "Region Hannover" ~ "Hannover",
# LK_Name == "Kaiserslautern" ~ "Landkreis Kaiserslautern",
# LK_Name == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz", .default = LK_Name))
# popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Kreis$", "")
# popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Stadt$", "")
# popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Freie und Hansestadt$", "")
# popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", kreisfreie Stadt$", "")
# popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Landeshauptstadt$", "")
# popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Stadtkreis$", "")
# popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Hansestadt$", "")
# 
# valuetoplot <- left_join(valuetoplot, popDensity)
# 
# #Regression Analysis
# 
# #Correlation of independent variables
# 
# cor(valuetoplot$Inhabitantsperkm2, valuetoplot$IncomePerson2022)
# cor(valuetoplot$Inhabitantsperkm2, valuetoplot$voterTurnout)
# #Corelations from here on forward 
# cor(valuetoplot$Inhabitantsperkm2, valuetoplot$unemploymentQuota)
# 
# cor(valuetoplot$IncomePerson2022, valuetoplot$voterTurnout)
# cor(valuetoplot$IncomePerson2022, valuetoplot$unemploymentQuota)
# 
# cor(valuetoplot$voterTurnout, valuetoplot$unemploymentQuota)
# 
# #Forward Selection
# #One Variable Models
# RegressionPopDens <- lm(value ~ Inhabitantsperkm2, data = valuetoplot)
# summary(RegressionPopDens)
# RegressionIncome <- lm(value ~ IncomePerson2022, data = valuetoplot)
# summary(RegressionIncome)
# RegressionVoter <- lm(value ~ voterTurnout, data = valuetoplot)
# summary(RegressionVoter)
# RegressionUnemployment <- lm(value ~ unemploymentQuota, data = valuetoplot)
# summary(RegressionUnemployment)
# #Population Density leads to the largest adj. R^2 (~ 0.23)
# #We continue with the model RegressionPopDens and add the other variables one by one
# #Two Variables Models
# RegressionDensIncome <- lm(value ~ Inhabitantsperkm2 + IncomePerson2022, data = valuetoplot)
# summary(RegressionDensIncome)
# RegressionDensVoter <- lm(value ~ Inhabitantsperkm2 + voterTurnout, data = valuetoplot)
# summary(RegressionDensVoter)
# RegressionDensUnemployment <- lm(value ~ Inhabitantsperkm2 + unemploymentQuota, data = valuetoplot)
# summary(RegressionDensUnemployment)
# #RegressionDensVoter leads to the largest adj. R^2 (~ 0.36)
# #We continue with this model
# #Three Variables Models
# RegressionDensVoterIncome <- lm(value ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022, data = valuetoplot)
# summary(RegressionDensVoterIncome)
# RegressionDensVoterUnemployment <- lm(value ~ Inhabitantsperkm2 + voterTurnout + unemploymentQuota, data = valuetoplot)
# summary(RegressionDensVoterUnemployment)
# #Income is significant (p<0.01) and increases adj. R^2 by ~ 1%
# #Final model RegressionDensVoterIncome
# valuetoplot <- valuetoplot %>% mutate(predicted = predict(RegressionDensVoterIncome))
# 
# ggplot(valuetoplot) +
#   geom_point(aes(x = value, y = predicted), color = "darkgreen")  +
#   theme_minimal() + 
#   geom_abline(slope=1, intercept = 0) +
#   xlab("Actual Value") +
#   ylab("Value Predicted by\nRegression Model") +
#   theme(text = element_text(size = 40))
# 
# #Backward elimination
# fullmodel <- lm(value ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + unemploymentQuota, data = valuetoplot)
# summary(fullmodel)  
# #Unemployment quota is not statistically significant (p>0.05) and is removed from the the model
# fullmodelMinusUnemployment <- lm(value ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022, data = valuetoplot)
# summary(fullmodelMinusUnemployment)
# #All three independent variables are statistically significant. Via backwar elimination we reach the same model as via forward selection
# 
# #Branch and bound
# valuetoplotRed <- valuetoplot %>% select(c(value, Inhabitantsperkm2, voterTurnout, IncomePerson2022, unemploymentQuota))
# model <- lm(value ~ ., data=valuetoplotRed)
# step(model) #Backward elimination using AIC --> Again, leads to the same model
# 
# #Model selection via exhaustive search
# #https://www.rdocumentation.org/packages/leaps/versions/3.2/topics/regsubsets
# exhaustivesearch <- regsubsets(value ~ ., data=valuetoplotRed)
# mod.summary <- summary(exhaustivesearch)
# which.min(mod.summary$bic)
# which.max(mod.summary$adjr2)
# 
# 
#   
#   
#   