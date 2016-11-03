#!/bin/perl -w

use strict;
use warnings;
use WWW::Curl::Easy;
use XML::LibXML;
use JSON qw( decode_json );
use Path::Class;

#Preenchimento obrigatório
my $token = "EAACEdEose0cBAFpx8o4QHzab7CB5Yd4elvjvhPZA0D4SBAqSg3lItv5zuKOUZA5G4MlP4l8Bk1eq6gjZAbZCgFN1OAyQoXRSQJzFXyQVZAU3W76xHihr7DTxdimyvMQCTKXhYmvPhyVUtDmhqRsP4vTEk0au6Pk8POyEFjyCeqgZDZD";
my $pageid = "303522857815";
my @postids = ("10154022172737816", "10154021857427816", "10154021505512816");

my $site = "https://graph.facebook.com/";
my $postid;
my $dir = dir("coletas");

foreach $postid (@postids){
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $date = "$year$mon$wday$hour$min$sec";
  my $post = "$pageid"."_"."$postid";
  my $params = "v2.8/$post/comments?fields=message&filter=stream&access_token=$token";
  # my $params = "v2.8/$post/comments?fields=message&filter=stream&limit=583&access_token=$token";
  # summary=true&fields=total_count&filter=stream
  my $url = $site.$params;

  my $curl = WWW::Curl::Easy->new;

  my $filename = "coletas/coleta_$postid"."_"."$date.txt";
  open my $fh, '>:encoding(UTF-8)', $filename;

  my $i = 1;

  my $total = 0;

  print "Iniciando coleta do post: $postid.\n";

  while (1){
    $curl->setopt(CURLOPT_HEADER,0);
    $curl->setopt(CURLOPT_URL, $url);

    my $response_body;
    $curl->setopt(CURLOPT_WRITEDATA, \$response_body);

    my $retcode = $curl->perform;

    my $decoded = decode_json($response_body);

    if ( $retcode == 0){

      my @comments = @{ $decoded->{'data'} };
      my $qtd = @comments;
      my $total += $qtd;

      print $qtd." comentários na página $i\n";

      foreach my $comment ( @comments ){
        print $fh $comment->{'message'}." ";
      }
      if ( $decoded->{'paging'}{'next'}){
        $url = $decoded->{'paging'}{'next'};
        $i++;
      } else {
        print $total." comentários coletados.\n";
        print "Fim da coleta!\n";
        close $fh;
        last;
      }
    } else {
      print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
    }
  }
}
