#!/bin/perl -w

use strict;
use warnings;
use WWW::Curl::Easy;
use JSON qw( decode_json );
use Path::Class;

#Preenchimento obrigatório
my $token = "1674998429480140|ZH183zE4uet1QQMojZZNm1baJ7A";

my $site = "https://graph.facebook.com/";

my $dir = dir("coletas");

my $inputfile = "urls.txt";
open ( my $inputfile_fh, '<', $inputfile)
  or die "Não consegui abrir $inputfile!\n";

while (my $row = <$inputfile_fh>) {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $date = "$year$mon$wday$hour$min$sec";

  chomp $row;
  my @fields = split(/\//, $row);
  my $page = $fields[3];
  my $postid = $fields[5];
  my $coletor = $fields[6];

  my $params = "v2.8/$page?access_token=$token";
  my $url = $site.$params;
  my $curl = WWW::Curl::Easy->new;

  $curl->setopt(CURLOPT_HEADER,0);
  $curl->setopt(CURLOPT_URL, $url);
  $curl->setopt(CURLOPT_WRITEDATA, \my $response_body);

  my $retcode = $curl->perform;
  my $decoded = decode_json($response_body);

  my $pageid;
  if ( $retcode == 0){
    $pageid = $decoded->{'id'};
  } else {
    print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
  }

  my $post = "$pageid"."_"."$postid";
  $params = "v2.8/$post/comments?fields=message&filter=stream&access_token=$token";
  # my $params = "v2.8/$post/comments?fields=message&filter=stream&limit=583&access_token=$token";
  # summary=true&fields=total_count&filter=stream

  $url = $site.$params;
  $curl = WWW::Curl::Easy->new;

  my $i = 1;
  my $c = 0;

  print "Iniciando coleta do post: $postid.\n";

  while (1){
    my $outputdir = "coletas/coleta_$postid"."_"."$date"."_"."$coletor/";
    mkdir $outputdir;

    $curl->setopt(CURLOPT_HEADER,0);
    $curl->setopt(CURLOPT_URL, $url);

    my $response_body;
    $curl->setopt(CURLOPT_WRITEDATA, \$response_body);

    my $retcode = $curl->perform;

    my $decoded = decode_json($response_body);

    if ( $retcode == 0){

      my @comments = @{ $decoded->{'data'} };
      my $qtd = @comments;

      print $qtd." comentários na página $i\n";

      foreach my $comment ( @comments ){
        # $comment->{'message'} =~ s/[^[:ascii:]]//g;
        $c++;
        my $outputfile = "$outputdir/comment$c".".txt";
        open my $outputfile_fh, '>:encoding(UTF-8)', $outputfile;
        print $outputfile_fh $comment->{'message'}."\r\n";
        close $outputfile_fh;
      }
      if ( $decoded->{'paging'}{'next'}){
        $url = $decoded->{'paging'}{'next'};
        $i++;
      } else {
        print $c." comentários coletados.\n";
        print "Fim da coleta!\n\n";
        last;
      }
    } else {
      print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
    }
  }
}
close $inputfile_fh;
