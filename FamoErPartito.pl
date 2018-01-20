#!/usr/bin/perl
use LWP::UserAgent;
use URI::Escape ;#qw( uri_escape uri_escape_utf8 ); # ('uri_escape');
use utf8;       #Necessario per far capire a Perl come trattare le lettere accentate nelle costanti
use JSON;# qw( decode_json );
use Data::Dumper;
use warnings;
use strict;
use Fcntl qw(:flock);
use Switch;

require "./FamoErPartito_algo.pl";

my $DBFile="/tmp/DB.txt";
my $lockfile = '/tmp/FamoErPartito_lockfile';
my $botKeyFile='/tmp/FamoErPartito_botKeyFile';

my %DB;  ### Chiave:update_id Valore:chiat_id
my $chatID=0;
my $updateID=0;
my $lastID=0;
my $lastChatID=0;  # ChatID relativo all'ultimo update_id *** Sarà inutile se risponderò agli ultimi id per ciascuna chat
my $lastID_DB=0;
my %lastID_CHAT;   # chiave chat_id Valore: lastID update della chat appena scaricate
my %lastID_CHAT_DB; #come %lastID_CHAT ma relatiivco al DB *** FORSE INUTILE ***
my $lastMessage="";
my $botKey="";

# Inizializzo queste variabili una volta nota la botKey
my $updateURL="";
my $sendMessageURL="";

my %keyboard=(
#    resize_keyboard => true,
    inline_keyboard => [
        [{
            text => 'Nome',
            callback_data => '/nome'
        },
        {
            text => '10 nomi',
            callback_data => '/10nomi'
        },
        {
            text => 'Help',
            callback_data => '/help'
        }]
    ]
);
#print encode_json \%keyboard;


my $HELP="Famo Er Partito.

Quante volte avresti voluto fare un partito ma ti sei fermato perchè non sapevi da dove cominciare. 
Ora puoi! Ti genererò un nome per irretire l'elettorato.

I comandi disponibili sono:
/help   - Un aiuto veloce per farti capire cosa posso fare
/nome   - Genero un nome per il tuo Partito
/10nomi - Genero 10 nomi per il tuo Partito tra cui scegliere";
####################################################################

sub scriviDB(){
    open(my $fh, '>:encoding(UTF-8)', $DBFile) or die "Could not open file '$DBFile' $!";

    foreach my $key (keys(%DB)){
        print $fh "$key:$DB{$key}\n";
    }
    close $fh;
}

sub leggiDB(){
    open(my $fh, '<:encoding(UTF-8)', $DBFile) or die "Could not open file '$DBFile' $!";

    while (my $row = <$fh>) {
        chomp $row;
        
        # update_id:chat_id
    	my ($update_id,$chat_id) = split(":",$row);
        $DB{$update_id}=$chat_id;

        # Aggiorno il DB chhtID -> update_id
        if (!defined $lastID_CHAT_DB{$chat_id} || $lastID_CHAT_DB{$chat_id}<$update_id){
            $lastID_CHAT_DB{$chat_id}=$update_id;
        }
    }
    my @revTemp=reverse sort(keys(%DB));
    $lastID_DB=$revTemp[0];
    close $fh;
}


sub gestisciUpdate(){
    
    my $ua = new LWP::UserAgent;
    $ua->agent("Mozilla/8.0");
    $ua->cookie_jar( {} ); 
    $ua->protocols_allowed( [ 'http','https'] );
#    $ua->proxy(['http', 'https']);

    my $res = $ua->get($updateURL);

    if ($res->is_success)
    {
        my $pageJSON=decode_json($res->content); 
    	my @results=@{$pageJSON->{'result'}};
	    foreach my $result (@results){
	        my $update_id = $result->{'update_id'};
            my $chatID=0;
            my $message="*** NON TESTO ***";

            if (exists $result->{'message'}){
    	        $chatID= $result->{'message'}{'chat'}{'id'};
#                print "*** $update_id - $chatID\n"; #DEBUG
            } elsif (exists $result->{'callback_query'}){
                $chatID= $result->{'callback_query'}{'message'}{'chat'}{'id'};
                # Recupero il testo del comando inviato con la callback_query
                $message=$result->{'callback_query'}{'data'};
#                print "--- callback $chatID\n"; #DEBUG
            }
            
            # Se ero in una call back_query nessuna delle seguenti condizioni è vera
            if (exists $result->{'message'}{'text'}){
                $message=$result->{'message'}{'text'};
            } elsif (exists $result->{'message'}{'sticker'}){
                $message="*** STICKER ***";
            }elsif(exists $result->{'message'}{'document'}){
                $message="*** DOCUMENTO ***";
            } elsif (exists $result->{'edited_message'}){
	    	    $chatID=$result->{'edited_message'}{'chat'}{'id'} ;
                $message=$result->{'edited_message'}{'text'};
    	    }

	        #print "$update_id -> $chatID\n";
	        $DB{$update_id}=$chatID;

            # Aggiorno il lastupdate_id al più recente
            if ($lastID<$update_id){
	        	$lastID=$update_id;
                $lastChatID=$chatID;
		        $lastMessage=$message;
#                print $message;print "\n"; ### DEBUG
    	    }

            # Aggiorno il lastupdate_id di ciascuna chat
            if (!defined $lastID_CHAT{$chatID} || $lastID_CHAT{$chatID}<$update_id){
#                $lastID_CHAT{$chatID}=$update_id;
                $lastID_CHAT{$chatID}{$update_id}=$lastMessage;
# DEBUG                print "$chatID -> $update_id -> $lastMessage\n";
            }
	    }   
    }    
}

sub getLastMessageFromChatID(){

}

sub generateResponseText(){
#   return "WORK IN PROGRESS...";
#   generaSostAgg(); print"\n";
#   generaVerboArtSostAgg(); print"\n";
#   generaVerboPrepArtSostAgg(); print"\n";
#   generaVerboAvverbo(); print"\n";

    my $tipo = int(rand(4));
    my $resp="";
    switch ($tipo){
        case 1 {$resp = generaSostAgg()}
        case 2 {$resp = generaVerboArtSostAgg()}
        case 3 {$resp = generaVerboPrepArtSostAgg()}
        case 0 {$resp = generaVerboAvverbo()}
    }
    return $resp;
}

## Richiede due parametri, la risposta e la chatID
sub publishResponse($$){
    my $chatID   = shift;
    my $response = shift;
    my $ua = new LWP::UserAgent;
    
    $ua->agent("Mozilla/8.0");
    $ua->cookie_jar( {} );
    $ua->protocols_allowed( [ 'http','https'] );
    my $resp= $ua->get(
        "$sendMessageURL" ."?chat_id=". uri_escape_utf8("$chatID") .
        "&text=".uri_escape_utf8($response).
        "&reply_markup=" . encode_json(\%keyboard)
    );
#    print Dumper($resp); #DEBUG
}

sub parseMessage(){
    my $response="";
    # Ciclo su tutti gli update_is
    for my $id (sort keys %DB){
        # Se l'id è già nel DB ho risposto e passo olte 
        if ($id <= $lastID_DB){
# DEBUG           print "jump $id\n";
            next;
        }

        # Rispondo alla chat
        my $chatID=$DB{$id};
        my $command=$lastID_CHAT{$chatID}{$id};
#        print "$id ($lastID) - $chatID  - $command \n"; #DEBUG

        # Parsing del comando
        if ($command eq "/help"){
            $response=$HELP;
        } elsif ($command eq "/nome"){
            $response=generateResponseText();
        } elsif ($command eq "/10nomi") {
            for (my $i=0;$i<10;$i++){
                $response .= generateResponseText(); $response .= "\n";
            }
        } 
        else {
            $response="Comando \"$command\"  non valido.\n$HELP\n";
        }
    
        publishResponse($chatID,$response);
    }   
}

sub DEBUG_PRINTALL(){
    print "***$lastID - $lastID_DB - $lastMessage\n";
    foreach my $key (keys %lastID_CHAT){
        foreach my $key2 (keys %{ $lastID_CHAT{$key} }){
            print "$key -> $key2 -> $lastID_CHAT{$key}{$key2}";
            print "\n";
        }
    }                    }
    foreach my $key (keys %lastID_CHAT_DB){
#    print "$key -> $lastID_CHAT{$key}\n";
}


sub ErrAndExit ($) {
    my $silent=shift;
    if ($silent ne "yes"){
        print "$0 già in esecuzione. Termino ";
        print "(File '$lockfile' è già lockato).\n";
    }
    exit(1);
}

#
#
# ################## MAIN #####################
#
#


#if ($botKey eq ""){
#    print "Devi impostare la variabile '\$botKey' con la chiave del bot definita su Telegram\n";
#    print "Non faccio nulla ed esco.\n";
#    exit(1)
#}

# Mi accerto di avere una sola istanza running
open(my $fhpid, '>', $lockfile) or die "error: open '$lockfile': $!";
flock($fhpid, LOCK_EX|LOCK_NB) or ErrAndExit("yes");

####### Ok ora parto sul serio ###########
open(my $fhkf,'<',$botKeyFile) or die "Errore nell'pertura del file con la chiave del bot $botKeyFile";
$botKey = <$fhkf>;
chomp($botKey);
close $fhkf;

$updateURL="https://api.telegram.org/bot$botKey/getUpdates";
$sendMessageURL="https://api.telegram.org/bot$botKey/sendMessage";

leggiDB(); # Recupero gli eventuali update_ID e chatID salvati in passato per evitare di rispondere a comandi già dati

# Ciclo perenne per trattare tutti gli update
while (1){
    gestisciUpdate();
    scriviDB();
# DEBUG keep-alive    print "$lastID $lastID_DB \n";

    parseMessage();
    $lastID_DB=$lastID;  # scorciatoia per evitare di rileggere tutto il DB visto che a meno di un blocco è già nell'hash DB

    # Ogni qualche secondo leggo gli update
    sleep(3);
}
#DEBUG_PRINTALL();
