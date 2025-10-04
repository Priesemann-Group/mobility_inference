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

#Preparing data for postprocessing

postprocessing_clean <- function(model, consideredWave, run, outcomeVariable) {
  model <- model
  #model <- "fourhundred"
  
  consideredWave <- consideredWave
  #consideredWave <- "firstwave"
  
  run <- run
  #run <- "2025-07-02_400LK_exp_UsedForPostprocessing"
  
  outcomeVariable <- outcomeVariable
  #outcomeVariable <- "d_C"
  #outcomeVariable <- "exponential"
  #outcomeVariable <- "yaxis_intercept"
  #outcomeVariable <- "slope"
  #outcomeVariable <- "shareLocalIncidence"
  
  
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
    # "Tuttlingen",  "Ulm",  "Waldshut", 
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
    #               "Tuttlingen",  "Ulm",  "Waldshut", 
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
    counties <- c("Ahrweiler", "Alb-Donau-Kreis", "Altenburger Land", "Altenkirchen",                       
                  "Altmarkkreis Salzwedel", "Altötting",  "Alzey-Worms", "Amberg",                             
                  "Amberg-Sulzbach", "Anhalt-Bitterfeld", "Ansbach", "Aschaffenburg",                      
                  "Augsburg", "Aurich", "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach", "Baden-Baden",                        
                  "Bamberg", "Bautzen", "Bayreuth", "Berchtesgadener Land",               
                  "Berlin", "Bernkastel-Wittlich", "Biberach", "Bielefeld", "Birkenfeld", "Böblingen",                          
                  "Bodenseekreis", "Bonn", "Börde", "Borken", "Brandenburg an der Havel", "Braunschweig", "Breisgau-Hochschwarzwald", "Bremen",                             
                  "Bremerhaven", "Burgenlandkreis", "Calw", "Celle" , "Cham", "Chemnitz", "Cloppenburg", "Coburg",                             
                  "Cochem-Zell", "Coesfeld", "Cuxhaven",  "Dachau", "Dahme-Spreewald", "Darmstadt-Dieburg",                  
                  "Deggendorf", "Delmenhorst", "Dessau-Roßlau", "Diepholz",                           
                  "Dillingen an der Donau", "Dingolfing-Landau", "Dithmarschen", "Donau-Ries", "Donnersbergkreis", "Dortmund",  "Dresden", "Duisburg",                           
                  "Düren", "Düsseldorf", "Ebersberg",  "Eichsfeld", "Eichstätt", "Eifelkreis Bitburg-Prüm", "Elbe-Elster",  "Emden", "Emmendingen", "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis",                           
                  "Erding", "Erfurt", "Erlangen", "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen", "Esslingen", "Euskirchen" , "Flensburg", "Forchheim", "Frankenthal (Pfalz)",  "Frankfurt (Oder)", "Frankfurt am Main", "Freiburg im Breisgau",               
                  "Freising", "Freudenstadt", "Freyung-Grafenau", "Friesland", "Fulda", "Fürstenfeldbruck","Fürth", "Garmisch-Partenkirchen","Gera", "Gießen","Gifhorn", "Görlitz",                            
                  "Goslar", "Gotha", "Göttingen",  "Greiz", "Groß-Gerau", "Günzburg", "Gütersloh", "Halle (Saale)",                      
                  "Hamburg" ,"Hameln-Pyrmont", "Hannover", "Harburg", "Harz", "Haßberge", "Heidekreis", "Heidenheim", "Heilbronn", "Heinsberg", "Helmstedt", "Herford",                            
                  "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildburghausen", "Hildesheim", "Hochsauerlandkreis", "Hochtaunuskreis","Hof", "Hohenlohekreis","Holzminden", "Höxter","Ilm-Kreis", "Ingolstadt",                        
                  "Jena", "Jerichower Land", "Kaiserslautern", "Karlsruhe", "Kassel", "Kaufbeuren", "Kelheim", "Kempten (Allgäu)", "Kiel", "Kitzingen",                          
                  "Kleve", "Koblenz", "Köln", "Konstanz", "Krefeld", "Kronach", "Lahn-Dill-Kreis",  "Landau in der Pfalz", "Landkreis Ansbach", "Landkreis Aschaffenburg",            
                  "Landkreis Augsburg", "Landkreis Bamberg","Landkreis Bayreuth", "Landkreis Coburg","Landkreis Fürth",  "Landkreis Heilbronn",               
                  "Landkreis Hof", "Landkreis Karlsruhe","Landkreis Landshut", "Landkreis Leipzig", "Landkreis München", "Landkreis Oldenburg",                
                  "Landkreis Osnabrück", "Landkreis Passau", "Landkreis Regensburg", "Landkreis Rostock",                  
                  "Landkreis Schweinfurt", "Landkreis Würzburg", "Landsberg am Lech",  "Landshut","Leer",  "Leipzig",                            
                  "Leverkusen", "Limburg-Weilburg", "Lippe",  "Lörrach", "Lübeck" , "Lüchow-Dannenberg", "Ludwigsburg",  "Ludwigslust-Parchim", "Lüneburg", "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart", "Main-Tauber-Kreis", "Mainz", "Mainz-Bingen", "Mannheim",                           
                  "Marburg-Biedenkopf", "Märkisch-Oderland", "Märkischer Kreis", "Mayen-Koblenz", "Mecklenburgische Seenplatte", "Meißen", "Memmingen", "Merzig-Wadern", "Mettmann", "Miesbach", "Miltenberg", "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach",                    
                  "Mühldorf am Inn", "Mülheim an der Ruhr", "München", "Münster", "Neckar-Odenwald-Kreis", "Neu-Ulm", "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen",                        
                  "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neustadt an der Weinstraße", "Neuwied", "Nordfriesland", "Nordsachsen", "Nordwestmecklenburg", "Nürnberg", "Nürnberger Land",  "Oberallgäu",                         
                  "Oberbergischer Kreis", "Oberhavel", "Oberspreewald-Lausitz", "Odenwaldkreis", "Oder-Spree",  "Offenbach", "Offenbach am Main", "Oldenburg", "Olpe", "Ortenaukreis","Osnabrück", "Ostalbkreis",                        
                  "Osterholz", "Ostholstein", "Ostprignitz-Ruppin", "Paderborn", "Passau", "Pforzheim", "Pinneberg", "Pirmasens", "Plön", "Potsdam", "Potsdam-Mittelmark", "Prignitz", "Rastatt", "Ravensburg", "Recklinghausen", "Regen",                              
                  "Regensburg", "Regionalverband Saarbrücken", "Remscheid",  "Rendsburg-Eckernförde", "Reutlingen", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss",                        
                  "Rhein-Sieg-Kreis", "Rheingau-Taunus-Kreis", "Rhön-Grabfeld", "Rosenheim", "Rostock",  "Rotenburg (Wümme)","Roth", "Rottal-Inn", "Rottweil", "Saale-Orla-Kreis", "Saalekreis", "Saalfeld-Rudolstadt", "Saarlouis", "Sächsische Schweiz-Osterzgebirge",   
                  "Salzgitter", "Salzlandkreis", "Schaumburg", "Schleswig-Flensburg", "Schmalkalden-Meiningen", "Schwabach",  "Schwäbisch Hall", "Schwalm-Eder-Kreis", "Schwandorf",  "Schwarzwald-Baar-Kreis",             
                  "Schweinfurt", "Schwerin", "Segeberg", "Siegen-Wittgenstein", "Sigmaringen", "Soest", "Sömmerda",  "Sonneberg", "Speyer", "Spree-Neiße", "Stade", "Städteregion Aachen",                
                  "Steinburg", "Steinfurt", "Stendal", "Straubing", "Straubing-Bogen", "Stuttgart", "Südliche Weinstraße", "Südwestpfalz","Suhl", "Teltow-Fläming",                     
                  "Tirschenreuth", "Traunstein", "Trier", "Trier-Saarburg","Tuttlingen", "Uckermark", "Uelzen", "Ulm","Unna", "Unstrut-Hainich-Kreis",              
                  "Viersen", "Vogelsbergkreis", "Vogtlandkreis",  "Vorpommern-Greifswald", "Vorpommern-Rügen", "Waldeck-Frankenberg","Warendorf", "Wartburgkreis","Weiden in der Oberpfalz", "Weilheim-Schongau","Weimar", "Weimarer Land","Weißenburg-Gunzenhausen", "Werra-Meißner-Kreis",                
                  "Westerwaldkreis", "Wiesbaden","Wilhelmshaven", "Wittenberg","Wittmund", "Wolfsburg", "Worms", "Wunsiedel im Fichtelgebirge","Wuppertal", "Würzburg","Zollernalbkreis", "Zweibrücken","Zwickau")
  }else if(model == "fourhundred"){
    counties <- c("Ahrweiler", "Aichach-Friedberg", "Alb-Donau-Kreis", "Altenburger Land", "Altenkirchen", "Altmarkkreis Salzwedel", "Altötting", "Alzey-Worms", "Amberg", "Amberg-Sulzbach", "Ammerland", "Anhalt-Bitterfeld", "Ansbach", "Aschaffenburg", "Augsburg", "Aurich", 
                  "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach", "Bad Tölz-Wolfratshausen", "Baden-Baden", "Bamberg", "Barnim", "Bautzen", "Bayreuth", "Berchtesgadener Land", "Bergstraße", "Berlin", "Bernkastel-Wittlich", "Biberach", "Bielefeld", "Birkenfeld", "Böblingen", "Bochum", "Bodenseekreis", "Bonn", "Börde", "Borken", "Bottrop", "Brandenburg an der Havel", "Braunschweig", "Breisgau-Hochschwarzwald", "Bremen", "Bremerhaven", "Burgenlandkreis", "Calw", "Celle", "Cham", "Chemnitz", "Cloppenburg", "Coburg", "Cochem-Zell", "Coesfeld", "Cottbus - Chóśebuz", "Cuxhaven", "Dachau", "Dahme-Spreewald", "Darmstadt", "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst", "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau", "Dingolfing-Landau", "Dithmarschen", "Donau-Ries", "Donnersbergkreis", "Dortmund", "Dresden", "Duisburg", "Düren", "Düsseldorf", "Ebersberg", "Eichsfeld", "Eichstätt", "Eifelkreis Bitburg-Prüm", "Elbe-Elster", "Emden", "Emmendingen", "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis", "Erding", "Erfurt", "Erlangen", "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen", "Esslingen", "Euskirchen", "Flensburg", "Forchheim", "Frankenthal (Pfalz)", "Frankfurt (Oder)", "Frankfurt am Main", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Friesland", "Fulda", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Gelsenkirchen", "Gera", "Germersheim", "Gießen", "Gifhorn", "Göppingen", "Görlitz", "Goslar", "Gotha", "Göttingen", "Grafschaft Bentheim", "Greiz", "Groß-Gerau", "Günzburg", "Gütersloh", "Hagen", "Halle (Saale)", "Hamburg", "Hameln-Pyrmont", "Hamm", "Hannover", "Harburg", "Harz", "Haßberge", "Havelland", "Heidekreis", "Heidelberg", "Heidenheim", "Heilbronn", "Heinsberg", "Helmstedt", "Herford", "Herne", "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildburghausen", "Hildesheim", "Hochsauerlandkreis", "Hochtaunuskreis", "Hof", "Hohenlohekreis", "Holzminden", "Höxter", "Ilm-Kreis", "Ingolstadt", "Jena", "Jerichower Land", "Kaiserslautern", "Karlsruhe", "Kassel", "Kaufbeuren", "Kelheim", "Kempten (Allgäu)", "Kiel", "Kitzingen", "Kleve", "Koblenz", "Köln", "Konstanz", "Krefeld", "Kronach", "Kulmbach", "Kusel", "Kyffhäuserkreis", "Lahn-Dill-Kreis", "Landau in der Pfalz", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Augsburg", "Landkreis Bamberg", "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Heilbronn", "Landkreis Hof", "Landkreis Kaiserslautern", "Landkreis Karlsruhe", "Landkreis Kassel", "Landkreis Landshut", "Landkreis Leipzig", "Landkreis München", "Landkreis Oldenburg", "Landkreis Osnabrück", "Landkreis Passau", "Landkreis Regensburg", "Landkreis Rosenheim", "Landkreis Rostock", "Landkreis Schweinfurt", "Landkreis Würzburg", "Landsberg am Lech", "Landshut", "Leer", "Leipzig", "Leverkusen", "Lichtenfels", "Limburg-Weilburg", "Lindau", "Lippe", "Lörrach", "Lübeck", "Lüchow-Dannenberg", "Ludwigsburg", "Ludwigshafen am Rhein", "Ludwigslust-Parchim", "Lüneburg", "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart", 
                  "Main-Tauber-Kreis", "Main-Taunus-Kreis", "Mainz", "Mainz-Bingen", "Mannheim", "Mansfeld-Südharz", "Marburg-Biedenkopf", "Märkisch-Oderland", "Märkischer Kreis", "Mayen-Koblenz", "Mecklenburgische Seenplatte", "Meißen", "Memmingen", "Merzig-Wadern", "Mettmann", "Miesbach", "Miltenberg", "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach", "Mühldorf am Inn", "Mülheim an der Ruhr", "München", "Münster", "Neckar-Odenwald-Kreis", "Neu-Ulm", "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neustadt an der Weinstraße", "Neuwied", "Nienburg/Weser", "Nordfriesland", "Nordhausen", "Nordsachsen", "Nordwestmecklenburg", "Northeim", "Nürnberg", "Nürnberger Land", "Oberallgäu", "Oberbergischer Kreis", "Oberhausen", "Oberhavel", "Oberspreewald-Lausitz", "Odenwaldkreis", "Oder-Spree", "Offenbach", "Offenbach am Main", "Oldenburg", "Olpe", "Ortenaukreis", "Osnabrück", "Ostalbkreis", "Ostallgäu", "Osterholz", "Ostholstein", "Ostprignitz-Ruppin", "Paderborn", "Passau", "Peine", "Pfaffenhofen an der Ilm", "Pforzheim", "Pinneberg", "Pirmasens", "Plön", "Potsdam", "Potsdam-Mittelmark", "Prignitz", "Rastatt", "Ravensburg", "Recklinghausen", "Regen", "Regensburg", "Regionalverband Saarbrücken", "Rems-Murr-Kreis", "Remscheid", "Rendsburg-Eckernförde", "Reutlingen", "Rhein-Erft-Kreis", "Rhein-Hunsrück-Kreis", "Rhein-Lahn-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss", "Rhein-Pfalz-Kreis", "Rhein-Sieg-Kreis", "Rheingau-Taunus-Kreis", "Rheinisch-Bergischer Kreis", "Rhön-Grabfeld", "Rosenheim", "Rostock", "Rotenburg (Wümme)", "Roth", "Rottal-Inn", "Rottweil", "Saale-Holzland-Kreis", "Saale-Orla-Kreis", "Saalekreis", "Saalfeld-Rudolstadt", "Saarlouis", "Saarpfalz-Kreis", "Sächsische Schweiz-Osterzgebirge", "Salzgitter", "Salzlandkreis", "Schaumburg", "Schleswig-Flensburg", "Schmalkalden-Meiningen", "Schwabach", "Schwäbisch Hall", "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis", "Schweinfurt", "Schwerin", "Segeberg", "Siegen-Wittgenstein", "Sigmaringen", "Soest", "Solingen", "Sömmerda", "Sonneberg", "Speyer", "Spree-Neiße", "St. Wendel", "Stade", "Städteregion Aachen", "Starnberg", "Steinburg", "Steinfurt", "Stendal", "Stormarn", "Straubing", "Straubing-Bogen", "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Suhl", "Teltow-Fläming", "Tirschenreuth", "Traunstein", "Trier", "Trier-Saarburg", "Tübingen", "Tuttlingen", "Uckermark", "Uelzen", "Ulm", "Unna", "Unstrut-Hainich-Kreis", "Unterallgäu", "Vechta", "Verden", "Viersen", "Vogelsbergkreis", "Vogtlandkreis", "Vorpommern-Greifswald", "Vorpommern-Rügen", "Vulkaneifel", "Waldeck-Frankenberg", "Waldshut", "Warendorf", "Wartburgkreis", "Weiden in der Oberpfalz", "Weilheim-Schongau", "Weimar", "Weimarer Land", "Weißenburg-Gunzenhausen", "Werra-Meißner-Kreis", "Wesel", "Wesermarsch", "Westerwaldkreis", "Wetteraukreis", "Wiesbaden", "Wilhelmshaven", "Wittenberg", "Wittmund", "Wolfenbüttel", "Wolfsburg", "Worms", "Wunsiedel im Fichtelgebirge", "Wuppertal", "Würzburg", "Zollernalbkreis", "Zweibrücken", "Zwickau")
  }
  
  counties <- as.data.frame(counties)
  colnames(counties) <- c("LK_Name")
  counties <- counties %>% mutate(index = row_number() - 1)
  
  if(outcomeVariable == "d_C"){
    disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/d_C.csv"))
    disFac_post <- disFac_post %>% mutate(index = ceiling(seq_len(nrow(disFac_post)) / 52)-1)
  }else if(outcomeVariable == "exponential"){
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
      mutate(valueInitWave = {
        integrand <- function(x) {yaxis_intercept * exp(-x/slope)}
        integrate(integrand, lower = 0, upper = 12)$value
      }) %>%
      mutate(valueSecondWave = {
        integrand <- function(x) {yaxis_intercept * exp(-x/slope)}
        integrate(integrand, lower = 30, upper = 51)$value
      }) %>%
      ungroup()
    disFac_post <- disFac_post %>% mutate(value = value*100/(840*52)) %>% mutate(valueInitWave = valueInitWave*100/(840*52)) %>% mutate(valueSecondWave = valueSecondWave*100/(840*52))
  }else if(outcomeVariable == "yaxis_intercept"){
    disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/multiplicator_C.csv"))
    colnames(disFac_post) <- c("index", "value")
  }else if(outcomeVariable == "slope"){
    disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/slope_C.csv"))
    colnames(disFac_post) <- c("index", "value")
  }else if(outcomeVariable == "shareLocalIncidence"){
    disFac_post <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", run, "/incidenceweight.csv"))
    colnames(disFac_post) <- c("index", "value")
  }
  
  disFac_post <- left_join(disFac_post, counties)
  
  if(model %in% c("counties", "fourhundred")){
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
                                                     KRS_NAME == "Nienburg (Weser)" ~ "Nienburg/Weser",
                                                     KRS_NAME == "Pirmasens, kreisfreie Stadt" ~ "Pirmasens",
                                                     KRS_NAME == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                                                     KRS_NAME == "Speyer, kreisfreie Stadt" ~ "Speyer",
                                                     KRS_NAME == "Trier, kreisfreie Stadt" ~ "Trier",
                                                     KRS_NAME == "Waldshut" ~ "Waldshut",
                                                     KRS_NAME == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz",
                                                     KRS_NAME == "Worms, kreisfreie Stadt" ~ "Worms",
                                                     KRS_NAME == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                                     KRS_NAME == "Zweibrücken, kreisfreie Stadt" ~ "Zweibrücken",
                                                     KRS_NAME == "Landau in der Pfalz, kreisfreie Stadt" ~ "Landau in der Pfalz",
                                                     KRS_NAME == "Cottbus, Stadt" ~ "Cottbus - Chóśebuz",
                                                     KRS_NAME == "Darmstadt, Wissenschaftsstadt" ~ "Darmstadt",
                                                     KRS_NAME == "Hagen, Stadt der FernUniversität" ~ "Hagen",
                                                     KRS_NAME == "Kaiserslautern" ~ "Landkreis Kaiserslautern",
                                                     KRS_NAME == "Kaiserslautern, kreisfreie Stadt" ~ "Kaiserslautern",
                                                     KRS_NAME == "Kassel, documenta-Stadt" ~ "Kassel",
                                                     KRS_NAME == "Kassel" ~ "Landkreis Kassel",
                                                     KRS_NAME == "Rosenheim" ~ "Landkreis Rosenheim",
                                                     KRS_NAME == "Lindau (Bodensee)" ~ "Lindau",
                                                     KRS_NAME == "Ludwigshafen am Rhein, kreisfreie Stadt" ~ "Ludwigshafen am Rhein",
                                                     KRS_NAME == "Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen an der Ilm",
                                                     KRS_NAME == "Solingen, Klingenstadt" ~ "Solingen",
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
                                   group == "Städtische Kreise" ~ "Town",
                                   group == "Ländlicher Kreis mit Verdichtungsansätzen" ~ "Medium Rural",
                                   group == "Dünn besiedelt ländlicher Kreis" ~ "Rural"))
    
  }
  
  if(outcomeVariable %in% c("d_C")){
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
    if(outcomeVariable %in% c("d_C")){
      colnames(disFac_post) <- c("rowNo", "diseaseFactor", "LK_no", "LK_Name", "group", "fedState", "group_eng", "date", "date2")
    }
  }
  
  disFac_post$group <- factor(disFac_post$group, levels = c("Grosse Grossstadt", "Kleine Grossstadt", "Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
  disFac_post$group_eng <- factor(disFac_post$group_eng, levels = c("Large City", "Small City", "Town", "Medium Rural", "Rural"))
  
  return(disFac_post)
}