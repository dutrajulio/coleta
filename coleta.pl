#!/bin/perl -w
# Feito em perl pq Deus quis

use strict;
use warnings;
use WWW::Curl::Easy;
use JSON qw( decode_json );
use Path::Class;

# Arquivo contendo o token
my $tokenfile = "token.txt";
my $token;
# Abro o arquivo
open ( my $token_fh, '<', $tokenfile)
  or die "Não consegui abrir $tokenfile!\n";
# Leio apenas a primeira linha e salvo o conteúdo na variável
while (<$token_fh>) {
  chomp;
  $token = $_;
  last;
}
# Fecho o arquivo....boa prática
close $token_fh;

# Endereço da API do Facebook
my $site = "https://graph.facebook.com/";

# Arquivo de entrada com as URLs dos posts dos quais coletaremos os comentários
my $inputfile = "urls.txt";

# Abro o arquivo acima pra dentro de um filehandler
open ( my $inputfile_fh, '<', $inputfile)
  or die "Não consegui abrir $inputfile!\n";

# Variável que contará o número total de comentários considerando todos os posts(URLs)
my $ct = 0;

# Percorro o filehandler linha-a-linha
while (my $row = <$inputfile_fh>) {
  #Ignoro linhas comentadas
  $row =~ /^#/ and next;

  # Me asseguro de não haver nada além da quebra de linha. Nem sei se é necessário.
  chomp $row;

  # Pego a data corrente para diferenciação dos diretórios de saída.
  # Assim não corremos o risco de sobrescrever o conteúdo de nenhum diretório com os comentários
  # de outro post.
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

  # Somando 1900 para que imprimir o ano correto
  $year += 1900;

  # Somando 1 pois o localtime retorna o mês começando de 0
  $mon += 1;

  # Montando string que será utilizada na criação dos diretórios de saída
  my $date = "$year$mon$mday$hour$min$sec";

  # Separo cada linha em campos
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

  # Instanciando um objeto curl
  my $curl = WWW::Curl::Easy->new;

  # Sem header pra permitir a leitura do json
  $curl->setopt(CURLOPT_HEADER,0);

  # Construção da URL para consulta que serve apenas para recuperar
  # o id da página de origem do post
  my $url = $site.$params;

  # Configuração da requisição e direcionamento da resposta para variável
  $curl->setopt(CURLOPT_URL, $url);
  $curl->setopt(CURLOPT_WRITEDATA, \my $response_body);

  # Realizo a consulta HTTP e gravo o código de retorno
  my $retcode = $curl->perform;

  # Decodifico o json contido no corpo da resposta
  my $decoded = decode_json($response_body);

  my $pageid;

  # Se o código de retorno é 0 então tudo bem.
  if ( $retcode == 0){
    # Identifico e gravo o id da página de origem do post
    $pageid = $decoded->{'id'};
  # Senão mostra qual merda aconteceu imprimindo o código de erro da requisição HTTP
  } else {
    print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
  }

  # Construo a identificação completa do post que é o "id da página"_"id do post"
  my $post = "$pageid"."_"."$postid";

  # Novos paramêtros, agora para a consulta dos comentários em si.
  # Usei o filtro stream pois segundo a documentação da API ele retorna todos os comentários
  # inclusive os de resposta na ordem cronológica.
  $params = "v2.8/$post/comments?fields=message&filter=stream&access_token=$token";

  # Construção da URL básica para consulta que recupera todos
  # os comentários de um determinado post
  $url = $site.$params;

  # Variável que contará o número de páginas. A API retorna a consulta páginada
  my $i = 1;

  # Varável que contará o número de comentários e servirá para separar os arquivos de saída
  # pra cada comentário
  my $c = 0;

  print "Iniciando coleta do post: $postid.\n";

  # Como eu fiquei com preguiça de fazer mais consultas a API e assim realizar um loop
  # de acordo com a quantidade de comentários ou páginas, então criei um loop "infinito"
  # que é controlado lá em baixo pelos próprios dados de páginação trazidos no json.
  while (1){
    # Seto e crio o diretório onde salvarei os arquivos com os comentários.
    my $outputdir = "coletas/coleta_$postid"."_"."$date"."_"."$colector/";
    mkdir $outputdir;

    # Configuração da requisição e direcionamento da resposta para variável, da
    # consulta que recupera todos os comentários de um determinado post
    $curl->setopt(CURLOPT_URL, $url);
    $curl->setopt(CURLOPT_WRITEDATA, \my $response_body);

    # Realizo a consulta HTTP e gravo o código de retorno
    my $retcode = $curl->perform;

    # Decodifico o json contido no corpo da resposta
    my $decoded = decode_json($response_body);

    # Se o código de retorno é 0 então tudo bem.
    # Senão mostra qual merda aconteceu imprimindo o código de erro da requisição HTTP
    if ( $retcode == 0){

      # Gravo o json decodificado
      my @comments = @{ $decoded->{'data'} };

      # Pego a quantidade de comentários na "página"
      my $qtd = @comments;

      # Só pra conferir o andamento do proceso em tempo de execução
      print $qtd." comentários na página $i\n";

      # Percorro o array com os comentários e pego um comentário por vez
      foreach my $comment ( @comments ){
        # Incremento a variável de contagem de comentários
        $c++;

        # Seto e abro o arquivo onde salvarei o comentário
        my $outputfile = "$outputdir/comment$c".".txt";
        open my $outputfile_fh, '>:encoding(UTF-8)', $outputfile
          or die "Não consegui abrir $outputfile!\n";

        # Salvo o comentário no arquivo
        print $outputfile_fh $comment->{'message'}."\r\n";

        # Fecho o arquivo....boa prática
        close $outputfile_fh;
      }

      # Verifico se o json possui o campo "next" dento do campo "paging"
      # Se tiver é porque existe mais uma página de comentários para esse post
      if ( $decoded->{'paging'}{'next'}){

        # Seto a URL de consulta com link da próxima página
        $url = $decoded->{'paging'}{'next'};

        # Incremento o contator de páginas
        $i++;

      # Senão é porque estou na última, ou única, página com comentários
      } else {
        # Somando o total de comtários em cada post
        $ct += $c;

        # Imprimo o resumo do que foi feito no post atual
        print $c." comentários coletados.\n";
        print "Fim da coleta!\n\n";

        # Saio do foreach e continuo para a próxima iteração do while.
        # Ou seja, passo pra próxima URL de post e inicio a coleta dos comentários.
        last;
      }
    # Esse é o senão da verificação do código da requisição que retorna os comentários
    } else {
      # Se chegou aqui é porque deu merda, então mostra qual foi imprimindo o código de erro da requisição HTTP
      print ("Merda, erro: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
    }
  }
}

# Imprimo o resumo do que foi feito em todos os posts
print $ct." comentários coletados considerando todos os posts.\n\n";

# Fecho o arquivo....boa prática
close $inputfile_fh;
