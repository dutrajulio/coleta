#!/bin/perl

use strict;
use warnings;
use WWW::Curl::Easy;
use XML::LibXML;
use JSON qw( decode_json );
use Path::Class;

my $token = "EAACEdEose0cBANBe26C7LUob0HFTXkv06k6sNbLcr8sB8MlJvOvHtrHE310Tn1Ljd22ZAXKl2RLNz49QyZAS5kuXzCfgVVcqVaM7NlLoMf3fCOqRbI3vVVBtCUOaKPmZBy4mPPEaqJUjNbuXT2rdGXPgW2SWJXb2ios0moJjwZDZD";
my $site = "https://graph.facebook.com/";
my $pageid = "5550296508";
my $postid = "10154847775816509";
my $post = "$pageid"."_"."$postid";
# my $params = "v2.8/$post/comments?fields=message&filter=stream&access_token=$token";
my $params = "v2.8/$post/comments?fields=message&filter=stream&limit=583&access_token=$token";
# summary=true&fields=total_count&filter=stream
my $url = $site.$params;

my $curl = WWW::Curl::Easy->new;

my $dir = dir("coletas");
my $file = $dir->file("coleta_$postid.txt");
my $file_handle = $file->openw();

while (1){
  $curl->setopt(CURLOPT_HEADER,0);
  $curl->setopt(CURLOPT_URL, $url);

  my $response_body;
  $curl->setopt(CURLOPT_WRITEDATA, \$response_body);

  my $retcode = $curl->perform;

  my $decoded = decode_json($response_body);

  if ( $retcode == 0){
    my @comments = @{ $decoded->{'data'} };
    foreach my $comment ( @comments ){
      $file_handle->print("Comentario: ".$comment->{'message'}."\n");
    }
    if ( $decoded->{'paging'}){
      $url = $decoded->{'paging'}{'next'};
    } else {
      exit;
    }
  } else {
    print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
  }
}
