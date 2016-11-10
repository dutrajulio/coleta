#!/bin/perl -w
# Feito em perl pq Deus quis

use strict;
use warnings;
use WWW::Curl::Easy;
use JSON qw( decode_json );
use Path::Class;

# Preenchimento obrigatório com o token gerado via https://developers.facebook.com/tools/explorer
my $token = "1674998429480140|ZH183zE4uet1QQMojZZNm1baJ7A";

# Endereço da API do Facebook
my $site = "https://graph.facebook.com/";

# Arquivo de entrada com as URLs dos posts dos quais coletaremos os comentários
my $inputfile = "urls.txt";

# Leio o arquivo acima pra dentro de um filehandler
open ( my $inputfile_fh, '<', $inputfile)
  or die "Não consegui abrir $inputfile!\n";

# Percorro o filehandler linha-a-linha
while (my $row = <$inputfile_fh>) {
  # Pego a data corrente para diferenciação dos diretórios de saída.
  # Assim não corremos o risco de sobrescrever o conteúdo de nenhum diretório com os comentários
  # de outro post.
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  # Somando 1900 para que imprimir o ano correto
  $year += 1900;
  # Somando 1 pois o localtime retorna o mês começando de 0
  $mon += 1;
  my $date = "$year$mon$mday$hour$min$sec";

  # Me asseguro de não haver nada além da quebra de linha. Nem sei se é necessário.
  chomp $row;
  # Separo cada linha em campos, mas só pego os que interessam.
  my @fields = split(/\//, $row);
  # A página de origem do post
  my $page = $fields[3];
  # O ID do post
  my $postid = $fields[5];
  # E um campo que adicionei por conta própria apenas para diferenciar o post um do outro.
  # Por ex. no caso de coletar para pessoas diferentes.
  my $colector = $fields[6];

  # Paramêtros básicos passados a API do facebook
  my $params = "v2.8/$page?access_token=$token";
  # Construção da URL básica e instanciamento da consulta que serve apenas para recuperar
  # o id da página de origem do post
  my $url = $site.$params;
  my $curl = WWW::Curl::Easy->new;
  # Sem header pra facilitar a leitura do json
  $curl->setopt(CURLOPT_HEADER,0);
  $curl->setopt(CURLOPT_URL, $url);
  $curl->setopt(CURLOPT_WRITEDATA, \my $response_body);

  # Realizo a requisição HTTP e gravo o código de retorno
  my $retcode = $curl->perform;
  # Decodifico o json contido no corpo da resposta
  my $decoded = decode_json($response_body);
  # Identifico e gravo o id da página de origem do post
  my $pageid;
  if ( $retcode == 0){
    $pageid = $decoded->{'id'};
  } else {
    print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
  }

  # Construo a identificação completa do post que é o "id da página"_"id do post"
  my $post = "$pageid"."_"."$postid";
  # Novos paramêtros agora para a consulta dos comentários em si.
  # Usei o filtro stream pois segundo a documentação da API ele retorna todos os comentários
  # inclusive os de resposta na ordem cronológica.
  $params = "v2.8/$post/comments?fields=message&filter=stream&access_token=$token";

  # Construção da URL básica e instanciamento da consulta que recupera todos
  # os comentários de um determinado post
  $url = $site.$params;
  $curl = WWW::Curl::Easy->new;

  # Variável que contará o número de páginas pois a API retorna a consulta páginada
  my $i = 1;
  # Varável que contará o número de comentários e servirá para separar os arquivos de saída
  # pra cada comentário
  my $c = 0;

  print "Iniciando coleta do post: $postid.\n";

  # Como eu fiquei com preguiça de fazer mais consultas a API rest e assim realizar um loop
  # de acordo com a quantidade de comentários ou páginas então criei um loop "infinito"
  # que é controlado lá em baixo pelos próprios dados de páginação trazidos no json.
  while (1){
    my $outputdir = "coletas/coleta_$postid"."_"."$date"."_"."$colector/";
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
        open my $outputfile_fh, '>:encoding(UTF-8)', $outputfile
          or die "Não consegui abrir $outputfile!\n";
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
