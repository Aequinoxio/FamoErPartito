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
use POSIX;

use Log::Log4perl qw(:easy);

require "./FamoErPartito_algo.pl";

# LOGICA DI UPDATE:
# Appena vengo eseguito recupero da Telegram l'ultimo updateID
# ad ogni aggiornamento recupero gli update ID maggiori del lastupdateID
# creo un hash temporaneo chatID:updateID con le chat da aggiornare e per ciascuna di esse recupero i msg in ordin ecrescente di update ID e rispondo
# imposto il past update ID all'ultimo trovato e ricnominco il ciclo
# in questo modo non devo conservare alcuno stato
#

my $gLockFile = '/tmp/FamoErPartito_lockfile';
my $gBotKeyFile='/tmp/FamoErPartito_botKeyFile';

my %gDBUidChIDMsg;  ### Chiave: update_id - Chiave:chat_ID - Valore: messaggio
my %gDBChIDName ;   ### Chiave: chat id - valore : username chat id

my $gLastTelegramID=0;  # Last updateID recuperata da Telegram
my $gLastChatID=0;      # ChatID relativo all'ultimo update_id *** Sarà inutile se risponderò agli ultimi id per ciascuna chat
my $gLastAnsweredID=0;  # last updateID a cui si è risposto. Codifica lo stato precedente della risposta
my $gLastMessage="";    #TODO: Forse è inutile
my $gBotKey="";

# Inizializzo queste variabili una volta nota la botKey
my $gUpdateURL="";
my $gSendMessageURL="";

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

my $ABOUT="Piccolo easter egg.

Sono un bot creato da GG (17ab8888540351f89f1b4dd21c6a451d) ispirato da un'osservazione di un giornalista sentita alla radio e relativa alle denominazioni dei partiti della campagna elettorale 2018.
Ovviamente stiamo solo giocando, l'impegno politico è una cosa seria come forse l'osservazione del giornalista voleva sottolineare: anche nei nomi che i partiti si danno occorre rispettare l'elettorato ed essere seri e non giocare con la loro pancia.
";
####################################################################

sub gestisciUpdate(){
    my $ua = new LWP::UserAgent;
    $ua->agent("Mozilla/8.0");
    $ua->cookie_jar( {} ); 
    $ua->protocols_allowed( [ 'http','https'] );
#    $ua->proxy(['http', 'https']);

    my $res = $ua->get($gUpdateURL);

    if ($res->is_success)
    {
        my $pageJSON=decode_json($res->content); 
    	my @results=@{$pageJSON->{'result'}};
        my $update_id;
        my $chatID;
        my $message;
        my $username;
        my %temp;   # Temp hash per i vari tipi di rami nel json
	    foreach my $result (@results){
	        $update_id = $result->{'update_id'};
            $chatID=0;
            $message="*** NON TESTO ***";

            if (exists $result->{'message'}){
    	        $chatID= $result->{'message'}{'chat'}{'id'};
#                $username= $result->{'message'}{'chat'}{'username'};
                %temp=%{$result->{'message'}{'chat'}};
                DEBUG "*** $update_id - $chatID\n"; #DEBUG
            } elsif (exists $result->{'callback_query'}){
                $chatID= $result->{'callback_query'}{'message'}{'chat'}{'id'};
                # Recupero il testo del comando inviato con la callback_query
                $message=$result->{'callback_query'}{'data'};
                %temp=%{$result->{'callback_query'}{'message'}{'chat'}};
#                $username=$result->{'callback_query'}{'message'}{'chat'}{'username'};
                DEBUG "--- callback $chatID\n"; #DEBUG
            }
           
            #Salvo lo username della chat
            if ($temp{'type'} eq "private"){
                $username=$temp{'username'};
            }elsif ($temp{'type'} eq "group"){
                $username=$temp{'title'};

            }else {
                $username="supergroup or channel";
            }

            $gDBChIDName{$chatID}=$username;

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

            # Se ho già trattato questo update ID salto al prossimo
            if ($update_id<=$gLastTelegramID){
#                print "jump\n";
                DEBUG "Salto";               
                next;
            } else {
#                print "saving\n";
                DEBUG "Salvo il nuovo update ID: $update_id per la chat: $chatID";
            }

            # Aggiorno il micro DB delle chat da gestire. Conservo solo l'ultimo messaggio a cui risponderò
	        #print "$update_id -> $chatID\n";
            $gDBUidChIDMsg{$update_id}{$chatID}=$message;
            $gLastTelegramID=$update_id;
            $gLastChatID=$chatID;
#            $gLastMessage=$message;
#            print Dumper (\%lastID_CHAT); print "\n"; #DEBUG
	    }   
    }    
}

sub generateResponseText(){
    my $tipo = int(rand(6));
    my $resp="";
    switch ($tipo){
        case 0 {$resp = generaVerboAvverbo()}
        case 1 {$resp = generaSostAgg()}
        case 2 {$resp = generaVerboArtSostAgg()}
        case 3 {$resp = generaVerboPrepArtSostAgg()}
        case 4 {$resp = generaSostantivoCongSost()}
        case 5 {$resp = generaAggettivoCongAggettivo()}
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
        "$gSendMessageURL" ."?chat_id=". uri_escape_utf8("$chatID") .
        "&text=".uri_escape_utf8($response).
        "&reply_markup=" . encode_json(\%keyboard)
    );
#    print Dumper($resp); #DEBUG
}

sub parseMessage(){
    my $response="";
    # Ciclo su tutti gli update_id
    for my $id (sort keys %gDBUidChIDMsg){
        # Se l'id è già nel DB che avevo salvato allora ho risposto e passo olte 
        if ($id <= $gLastAnsweredID){
#            print "jump $id\n";  # DEBUG
            next;
        }

        # Rispondo alla chat
        my @chatIDs=sort keys $gDBUidChIDMsg{$id};
        my $chatID=$chatIDs[0];  # Recupero il massimo valore. Lo faccio per sicurezza
#        DEBUG "latest chatID: $chatID max chatIDs: $#chatIDs - $chatIDs[0]\n";
        my $command=$gDBUidChIDMsg{$id}{$chatID};
#        DEBUG  "$id ($lastID) - $chatID  - $command \n"; #DEBUG

        # Parsing del comando
        if ($command eq "/help"){
            $response=$HELP;
        } elsif ($command eq "/nome"){
            $response=generateResponseText();
        } elsif ($command eq "/10nomi") {
            for (my $i=0;$i<10;$i++){
                $response .= generateResponseText(); $response .= "\n";
            }
        } elsif ($command eq "/about"){
            $response=$ABOUT;
        }
        else {
            $response="Comando \"$command\"  non valido.\n$HELP\n";
        }

        INFO "Rispondo alla chat: $gDBChIDName{$chatID} (id:$chatID) comando:  $command\n"; #DEBUG    
        publishResponse($chatID,$response); ### TODO: RIPRISTINARE DOPO IL DEBUG SUGLI UPDATE ID
    }   
}

sub ErrAndExit ($) {
    my $silent=shift;
    if ($silent ne "yes"){
        print "$0 già in esecuzione. Termino ";
        print "(File '$gLockFile' è già lockato).\n";
    }
    exit(1);
}

# Mi accerto di avere una sola istanza running
sub checkRunningInstance($){
    my $lockFile = shift;
    DEBUG "In checkRunningInstance() $gLockFile";
    open(my $fhpid, '>', $lockFile) or die "error: open '$lockFile': $!";
    flock($fhpid, LOCK_EX|LOCK_NB) or ErrAndExit("yes");

#    unless (flock($fhpid, LOCK_EX|LOCK_NB)) {
#        warn "can't immediately write-lock the file ($!), blocking ...";
#        unless (flock($fhpid, LOCK_EX)) {
#            die "can't get write-lock on numfile: $!";
#        }
#    }
#    return 1;
}

# Carico la botKey ed imposto le variabili con le URL per la risposta
sub getBotKeyAndInitURLS(){
    open(my $fhkf,'<',$gBotKeyFile) or die "Errore nell'pertura del file con la chiave del bot $gBotKeyFile";
    $gBotKey = <$fhkf>;
    chomp($gBotKey);
    close $fhkf;

    $gUpdateURL="https://api.telegram.org/bot$gBotKey/getUpdates";
    $gSendMessageURL="https://api.telegram.org/bot$gBotKey/sendMessage";
}


# ################## MAIN #####################
#Log::Log4perl->easy_init($DEBUG);
Log::Log4perl->easy_init($INFO);

# Una sola istanza deve essere running
#checkRunningInstance($gLockFile) ;  #Sembra che se faccio questo check in una sub non funzioni!!!
open(my $fhpid, '>', $gLockFile) or die "error: open '$gLockFile': $!";
flock($fhpid, LOCK_EX|LOCK_NB) or ErrAndExit("yes");

getBotKeyAndInitURLS();

$gLastTelegramID=0;
$gLastAnsweredID=0;

# Leggo i dati nella chat e scarto tutti gli eventuali messaggi presenti
gestisciUpdate();
$gLastAnsweredID=$gLastTelegramID;

# Qualche log
print "Bot started - last ID answered=$gLastAnsweredID - last ID from Telegram=$gLastTelegramID - salto tutti i messaggi, inizio a rispondere ai nuovi da ora: ";
print strftime "%F %T", localtime $^T;
print "\n";

# Ciclo perenne per trattare tutti gli update
while (1){
    gestisciUpdate();
    parseMessage();
    $gLastAnsweredID=$gLastTelegramID; # scorciatoia per evitare di rileggere tutto il DB visto che a meno di un blocco è già nell'hash DB
#   print "Bot running - last ID answered=$gLastAnsweredID - last ID from Telegram=$gLastTelegramID \n";
    DEBUG "The bot is running";
    # Aspetto un po' prima di rileggere gli update
    sleep(3);
}
