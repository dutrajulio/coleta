#!/bin/perl -w

use strict;
use warnings;
use WWW::Curl::Easy;
use XML::LibXML;
use JSON qw( decode_json );
use Path::Class;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
my $date = "$year$mon$wday$hour$min$sec";

my $token = "1820225528248588|v8dvIGo5mmcAawIWsjdruqnOqxs";
my $site = "https://graph.facebook.com/";
my $pageid = "5550296508";
my $postid = "10155489801406509";
my $post = "$pageid"."_"."$postid";
my $params = "v2.8/$post/comments?fields=message&filter=stream&access_token=$token";
# my $params = "v2.8/$post/comments?fields=message&filter=stream&limit=583&access_token=$token";
# summary=true&fields=total_count&filter=stream
my $url = $site.$params;

my $curl = WWW::Curl::Easy->new;

my $dir = dir("coletas");
my $filename = "coletas/coleta_$postid"."_"."$date.txt";
open my $fh, '>:encoding(UTF-8)', $filename;

my $i = 1;

my $total = 0;

print "Iniciando coleta.\n";

while (1){
  $curl->setopt(CURLOPT_HEADER,0);
  $curl->setopt(CURLOPT_URL, $url);

  my $response_body;
  $curl->setopt(CURLOPT_WRITEDATA, \$response_body);

  my $retcode = $curl->perform;

  # print $response_body."\n";

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
      exit;
    }
  } else {
    print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
  }
}
