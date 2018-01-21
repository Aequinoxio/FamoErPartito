#!/usr/bin/perl
use strict;
use warnings;
use utf8;

# ###################################################################
# Costanti
# ###################################################################
#

my @genereQuanto = (  # s = singolare, p = plurale, m = maschile, f = femminile
    "sm", 
    "pm",
    "sf",
    "pf"
);

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
    "Libero"        => {"sm" => "Libero", "sf" => "Libera", "pm" => "Liberi", "pf" => "Libere"},
    "Avanti"        => {"sm" => "Avanti", "sf" => "Avanti", "pm" => "Avanti", "pf" => "Avanti"},
    "Sovrano"       => {"sm" => "Sovrano", "sf" => "Sovrana", "pm" => "Sovrani", "pf" => "Sovrane"},
    "Tutto"         => {"sm" => "Tutto", "sf" => "Tutta", "pm" => "Tutti", "pf" => "Tutte"},
    "Sociale"       => {"sm" => "Sociale", "sf" => "Sociale", "pm" => "Sociali", "pf" => "Sociali"}, 
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
    "Diritti"       => "pm" ,
    "Basta"         => "sf" ,
    "Costituzione"  => "sf" ,
    "Identità"      => "sf"
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
#    "o",
#    "sia",
    "ma anche",
    ""              # TODO: Work around: per i sostantivi non va bene mentre va bene per due aggettivi, allora deve essere sempre l'ultima

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
    "Agire",
    "Amministrare",
    "Avanzare",
    "Cambiare",
    "Camminare",
    "Comprendere",
    "Condividere",
    "Conseguire",
    "Costruire",
    "Creare",
    "Credere",
    "Crescere",
    "Difendere",
    "Far Evolvere",
    "Far progredire",
    "Fare",
    "Favorire",
    "Fondare",
    "Ideare",
    "Innovare",
    "Immaginare",
    "Inventare",
    "Migliorare",
    "Partecipare",
    "Potenziare",
    "Proporre",
    "Proseguire",
    "Realizzare",
    "Rifare",
    "Riformare",
    "Rinnovare",
    "Scegliere",
    "Sostenere",
    "Sviluppare",
    "Unire",
    "Unirsi"
);

my %articoli=(
    "il" => {"sm" => "il", "sf" => "la", "pm" => "i", "pf" => "le"},
    "lo" => {"sm" => "lo", "sf" => "", "pm" => "gli", "pf" => ""}
);


# ##################
# Subs di ausilio
# ##################

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
    my $verbo = $verbi[int(rand($#verbi+1))];
    return $verbo;
}

sub randAvverbio(){
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

# Genera un aggettivo randomico a second adel sostantivo o del genere (sf, sm ecc.) passato
sub randAggettivo($){
    my $param=shift;
    my $sostantivo="";
    my $genere="";

    # Verifico se ho un sostantivo valido o se ho passato un genere quantificato (sm ecc.)
    # Reupero il genere rlativo al sostantivo o imposto il genere passato come parametro
    if (exists $sostantivi{$param}){
        $genere=$sostantivi{$param};
        $sostantivo=$param;
    } elsif (grep {$_ eq $param } @genereQuanto){
        $genere=$param;
    }

    my @aggKeys =keys(%aggettivi);

    # Recupero la chiave dell'aggettivo cioà la sua forma principale
    my $agg=int(rand($#aggKeys+1));
    my $aggTemp=$aggKeys[$agg];

    # Recupero al forma corretta in base al genere del sostantivo
    my $aggettivo=$aggettivi{$aggTemp}{$genere};
     
    return $aggettivo;
}

# Di default elimino l'ultima congiunzione - quella vuota -  (vedi commento all'array @congiunzioni)
# Se passo un parametro qualunque allora considero l'intero array
# Faccio così perchè posso legare due aggettivi anche senza nulla ma con due sostantivi è "brutto"
#
sub randCongiunzione(){
    my $param = shift;
    my $cong = "" ;
    if ( defined $param){
        $cong = $congiunzioni[int(rand($#congiunzioni+1))];
    } else {
        $cong = $congiunzioni[int(rand($#congiunzioni))];
    }

    return $cong;
}

sub randPreposizione(){
    my $prep = $preposizioni[int(rand($#preposizioni+1))];
    return $prep;
}

sub randGenereQuanto(){
    my $genQ = $genereQuanto[int(rand($#genereQuanto+1))];
    return $genQ;
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
    return $resp;
}

# Verbo preposizione articolo sostantivo aggettivo
sub generaVerboPrepArtSostAgg(){
    my $sostantivo=randSostantivo();
    my $resp = randVerbo() . " " . randPreposizione() . " " . articolo($sostantivo) . " " . $sostantivo . " " . randAggettivo($sostantivo);
    $resp = pulisciRisposta($resp);
    return $resp;
}

sub generaVerboAvverbo(){
    my $resp = randVerbo() . " " . randAvverbio() ;
    $resp = pulisciRisposta($resp);
    return $resp;
}

sub generaSostantivoCongSost(){
    my $resp = randSostantivo() . " " . randCongiunzione() . " " . randSostantivo();
    $resp = pulisciRisposta($resp);
    return $resp;
}

sub generaAggettivoCongAggettivo(){
    my $genere = randGenereQuanto();
    # Quanche check
    my $agg1 = randAggettivo($genere);
    my $agg2 = randAggettivo($genere);
    my $cong = randCongiunzione();
    my $resp = "";

    # TODO: spostare i controlli semantici in una apposita routine. Ora faccio solo una verifica semplicissima e rigenero
    # tutto finchè non ho una coppia che mi soddisfa. Termino comunque dopo 10 iterazioni
    my $counter=0;
    while (($agg2 eq "Basta" || $agg1 eq "!") and ($counter++ < 10)){
        $agg1 = randAggettivo($genere);
        $agg2 = randAggettivo($genere);
        $cong = randCongiunzione();
    }

    if ($agg2 eq "!"){
        $cong="";
    }

    $resp = $agg1 . " " . $cong . " " . $agg2;
    $resp = pulisciRisposta($resp);
    return $resp;
}

#
########### PER I MODULI DEVE TORNARE TRUE #########
1
