#!/usr/bin/perl
use strict;
use warnings;

####################################################################

############
# Regole:
# - Verbi [preposizione + articolo] sostantivi
# - Preposizione Sostantivi articolo  aggettivi
# - Sostantivi + preposizione articolo  Sostantivi
# - Verbi + avverbi
############


my %aggettivi=(
    "Italiano"      => {"sm" => "Italiano", "sf" => "Italiana", "pm" => "Italiani", "pf" => "Italiane"},
    "Europeo"       => {"sm" => "Europeo", "sf" => "Europea", "pm" => "Europei", "pf" => "Europee"},
    "Democratico"   => {"sm" => "Democratico", "sf" => "Democratica", "pm" => "Democratici", "pf" => "Democratiche"},
    "Progressista"  => {"sm" => "Progressista", "sf" => "Progressista", "pm" => "Progressisti", "pf" => "Progressiste"},
    "Popolare"      => {"sm" => "Popolare", "sf" => "Popolare", "pm" => "Popolari", "pf" => "Popolari"},
    "Civico"        => {"sm" => "Civico", "sf" => "Civica", "pm" => "Civici", "pf" => "Civiche"},
    "Civile"        => {"sm" => "Civile", "sf" => "Civile", "pm" => "Civili", "pf" => "Civili"},
    "Unito"         => {"sm" => "Unito", "sf" => "Unita", "pm" => "Uniti", "pf" => "Unite"},
    "Uguale"        => {"sm" => "Uguale", "sf" => "Uguale", "pm" => "Uguali", "pf" => "Uguali"},
    "Libero"        => {"sm" => "Libero", "sf" => "Libere", "pm" => "Liberi", "pf" => "Libere"},
    "Avanti"        => {"sm" => "Avanti", "sf" => "Avanti", "pm" => "Avanti", "pf" => "Avanti"},
    "Sovrano"       => {"sm" => "Sovrano", "sf" => "Sovrana", "pm" => "Sovrani", "pf" => "Sovrane"},
    "Tutto"         => {"sm" => "Tutto", "sf" => "Tutta", "pm" => "Tutti", "pf" => "Tutto"},
    "!"             => {"sm" => "!", "sf" => "!", "pm" => "!", "pf" => "!"}
);

my %sostantivi=(
    "Italia"        => "sf" , 
    "Europa"        => "sf" , 
    "Democrazia"    => "sf" , 
    "Libertà"       => "sf" , 
    "Popolo"        => "sm" , 
    "Sinistra"      => "sf" , 
    "Centro"        => "sm" , 
    "Destra"        => "sf" , 
    "Unità"         => "sf" ,
    "Uguaglianza"   => "sf" ,
    "Sovranità"     => "sf" ,
    "Civiltà"       => "sf" ,
    "Solidarietà"   => "sf" ,
    "Fratello"      => "sm" ,
    "Fratelli"      => "pm" ,
    "Scelta"        => "sf" ,
    "Scelte"        => "pf" , 
    "Costruzione"   => "sf" , 
    "Costruzioni"   => "pf" , 
    "Partecipazione"=> "sf" ,
    "Moderato"      => "sm" ,
    "Moderati"      => "pm" ,
    "Radicale"      => "sm" ,
    "Radicali"      => "pm" ,
    "Unione"        => "sf" ,
    "Unioni"        => "pf" , 
    "Partito"       => "sm" ,
    "Movimento"     => "sm" ,
    "Patto"         => "sm" ,
    "Riforma"       => "sf" ,
    "Riforme"       => "pf" , 
    "Futuro"        => "sm" ,
    "Giustizia"     => "sf" ,
    "Uguale"        => "sm" ,
    "Uguali"        => "pm" ,
    "Bene"          => "sm" ,
    "Avanti"        => "sm" ,
    "Centristi"     => "pm" ,
    "Valore"        => "sm" ,
    "Valori"        => "pm" ,
    "Diritto"       => "sm" ,
    "Diritti"       => "pm"
);

my @preposizioni=(
#    "di", # a togliere?
    "per",
    "con",
    ""
    
    # a, con, da, di, fra/tra, in. per, su
);

my @congiunzioni=(
    "e",
    ""
);

my @avverbi=(
    "insieme",
    "di più",
    "sempre",
    "bene",
    "avanti",
    "presto",
    "uniti",
    "!",
    ""
);

my @verbi=(
    "Costruire",
    "Riformare",
    "Partecipare",
    "Fare",
    "Scegliere",
    "Proporre",
    "Unire",
    "Unirsi",
    "Camminare",
    "Far progredire"
);

my %articoli=(
    "il" => {"sm" => "il", "sf" => "la", "pm" => "i", "pf" => "le"},
    "lo" => {"sm" => "lo", "sf" => "", "pm" => "gli", "pf" => ""}
);


# ##################
# Subs di ausilio
# @@@@@@@@@@@@@@@@@@

sub articolo($){
    my $sostantivo=shift;
    my $genere=$sostantivi{$sostantivo};   # Genere del sostantivo
    my $articolo=$articoli{"il"}{$genere};

    # Trattare i casi con lo e gli e l'
    # Fonte Treccani
    # – davanti a parole che cominciano con i o j + vocale (pronunciate, cioè, come ➔semiconsonanti), con gn (gnomo), con s + consonante, con sc (sci), con x, y, z e con i gruppi pn e ps
    # – davanti a parole che cominciano con una consonante + consonante diversa da l o r
    #
    # Il singolare l’ (con ➔elisione) e il plurale gli si usano davanti a parole che cominciano con una vocale 
    #

    # Imposto bene l'articolo per le eccezioni
    if ($genere eq "sm" || $genere eq "pm"){
        if ($sostantivo=~ m/^(sc|gn|i[aeiou]|j[aeiou]|s[^aeiou]|[^aeiou][^aeioulr]|i|x|y|z|pn|ps)/ig){
            $articolo= $articoli{"lo"}{$genere};
        } elsif ($sostantivo =~ m/^[aeiou]/ig) {
            if ($genere eq "sm"){
                $articolo="l'";
            } else {
                $articolo="gli";
            }
        }
    } elsif (($sostantivo=~m/^[aeiou]/gi) && $genere eq "sf") {
        $articolo="l'";
    }
    return $articolo;
}

sub randVerbo(){
    # Scelgo una congiunzione per legarli
    my $verbo = $verbi[int(rand($#verbi+1))];

    return $verbo;
    
}

sub randAvverbio(){
    # Scelgo una congiunzione per legarli
    my $avverbio = $avverbi[int(rand($#avverbi+1))];

    return $avverbio;
}

sub randSostantivo(){
    my @sostKeys=keys(%sostantivi);
    my $sostK=int(rand($#sostKeys+1));

    my $sostantivo=$sostKeys[$sostK];       # Sostantivo da stampare
    my $sostGen=$sostantivi{$sostantivo};   # Genere del sostantivo

    #return ($sostantivo,$sostGen);
    return $sostantivo;
}

sub randAggettivo($){
    my $sostantivo=shift;
    my $genere=$sostantivi{$sostantivo};
    my @aggKeys =keys(%aggettivi);
   # Recupero la chiave dell'aggettivo cioà la sua forma principale
    my $agg=int(rand($#aggKeys+1));
    my $aggTemp=$aggKeys[$agg];

    # Recupero al forma corretta in base al genere del sostantivo
    my $aggettivo=$aggettivi{$aggTemp}{$genere};
     
    return $aggettivo;
}

sub randCongiunzione(){
    # Scelgo una congiunzione per legarli
    my $cong = $congiunzioni[int(rand($#congiunzioni+1))];
    return $cong;
}

sub randPreposizione(){
# Scelgo una congiunzione per legarli
    my $prep = $preposizioni[int(rand($#preposizioni+1))];
    return $prep;
}

##### TODO: ELIMINARE ? ########
################################
sub generateResponseTextSeA(){
    # Recupero le chiavi. Quella dei sostantivi mi servirà per trovare il genere dell'aggettivo
    my @sostKeys=keys(%sostantivi);
    my @aggKeys =keys(%aggettivi);

    my $sostK=int(rand($#sostKeys+1));
    my $sostantivo=$sostKeys[$sostK];       # Sostantivo da stampare
    my $sostGen=$sostantivi{$sostantivo};   # Genere del sostantivo

    # Recupero la chiave dell'aggettivo cioà la sua forma principale
    my $agg=int(rand($#aggKeys+1));
    my $aggTemp=$aggKeys[$agg];
    
    # Recupero al forma corretta in base al genere del sostantivo
    my $aggettivo=$aggettivi{$aggTemp}{$sostGen};

    # Scelgo una congiunzione per legarli
    my $cong = $congiunzioni[int(rand($#congiunzioni+1))]; 
#    my $cong="";

    # La risposta
    # TODO: filtrare alcuni csi spuri es con "Avanti"
    my $response="$sostantivo $cong $aggettivo";
    $response =~ s/ +/ /;
    return $response;
}


sub pulisciRisposta($){
    my $resp=shift;
    $resp =~ s/\s+!/!/g;
    $resp =~ s/'\s+/'/g;
    $resp =~ s/\s+/ /g;

    return $resp;
}

# ##############################################################################
# Fine subs di ausilio
# ##############################################################################

# ##############################################################################
# Subs per la generazione frasi
# ##############################################################################
## Regole:
## - Verbi [preposizione + articolo] sostantivi
## - Preposizione Sostantivi articolo  aggettivi
## - Sostantivi + preposizione articolo  Sostantivi
## - Verbi + avverbi
# ##############################################################################

sub generaSostAgg(){
    my $sostantivo=randSostantivo();
    my $resp=$sostantivo . " " . randAggettivo($sostantivo);
    $resp = pulisciRisposta($resp);
    return $resp;
}

sub generaVerboArtSostAgg(){
    my $sostantivo=randSostantivo();
    my $resp = randVerbo() . " " . articolo($sostantivo) ." " . $sostantivo ." " . randAggettivo($sostantivo);
    $resp = pulisciRisposta($resp);
}

# Verbo preposizione articolo sostantivo aggettivo

sub generaVerboPrepArtSostAgg(){
    my $sostantivo=randSostantivo();
    my $resp = randVerbo() . " " . randPreposizione() . " " . articolo($sostantivo) . " " . $sostantivo . " " . randAggettivo($sostantivo);
    $resp = pulisciRisposta($resp);                     
}

sub generaVerboAvverbo(){
    my $resp = randVerbo() . " " . randAvverbio() ;
    $resp = pulisciRisposta($resp);
}


##########################
# DEBUG
# my $maxFrasi=10;
# for (my $i=0;$i<$maxFrasi;$i++){
#     print generaSostAgg(); print"\n";
#     print generaVerboArtSostAgg(); print"\n"; 
#     print generaVerboPrepArtSostAgg(); print"\n";
#     print generaVerboAvverbo(); print"\n";
# }



# print "-- Sostantivi e aggettivi\n";
# for (my $i=0;$i<$maxFrasi;$i++){
#     print generateResponseTextSeA();
#     print "\n";
# }
# 
# print "-- Sostantivi e aggettivi\n";
# for (my $i=0;$i<$maxFrasi;$i++){
#     my $sostantivo=randSostantivo();
#     my $resp=$sostantivo ." " .randAggettivo($sostantivo);
#     $resp =~ s/\s+!/!/g;
#     print $resp;
#     print "\n";
# }
# 
# print "-- Verbo articolo sostantivi e aggettivi\n";
# for (my $i=0;$i<$maxFrasi;$i++){
#     my $sostantivo=randSostantivo();
# 
#     print randVerbo() . " " ;
#     print articolo($sostantivo) ." ";
#     print $sostantivo ." " ;
#     print randAggettivo($sostantivo);
#     print "\n";
# }
# 
# #print "-- Verbo articolo sostantivi\n";
# #for (my $i=0;$i<$maxFrasi;$i++){
# #    my $sostantivo=randSostantivo();
# #
# #    print randVerbo() . " " ;
# #    print articolo($sostantivo) ." ";
# #    print $sostantivo ." " ;
# #    print "\n";
# #}
# 
# print "-- Verbo avverbio\n";
# for (my $i=0;$i<$maxFrasi;$i++){
# 
#     print randVerbo() . " " ;
#     print randAvverbio() ;
#     print "\n";
# }
# 
# print "-- Verbo preposizione articolo sostantivo aggettivo\n";
# for (my $i=0;$i<$maxFrasi;$i++){
#     my $sostantivo=randSostantivo();
#     print randVerbo() . " " ;
#     print randPreposizione() . " ";
#     print articolo($sostantivo). " ";
#     print $sostantivo . " ";
#     print randAggettivo($sostantivo);
#     print "\n";
# }
# 
