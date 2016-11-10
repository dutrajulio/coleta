# Coleta
Script que coleta comentários de posts no Facebook

Escrito em perl
  * Precisa dos seguintes módulos
    * WWW::Curl::Easy
    * JSON
    * Path::Class
Utiliza versão 2.8 da API graph

Passo-a-Passo:
  * Acesse https://developers.facebook.com
  * Faça seu cadastro
  * No canto superior direito clique em "Meus aplicativos" e "Adicionar um novo aplicativo"
  * Preencha os dados a gosto
  * Clique em "Ferramentas e suporte"
  * Clique em "Graph API Explorer"
  * Em "Aplicativo: [?]" selecione o aplicativo recém criado
  * Em "Get token" selecione "Get App Token"
  * Copie o conteúdo gerado no campo "Token de acesso:" e cole no arquivo "token.txt"
Exemplo: token.txt
-------------------
```
1674998429480140|ZH183zE4uet1QQMojZZNm1baJ7A
```
  * Preencha o arquivo "urls.txt" com os links dos posts um por linha. Ao final de cada linha acrecente "/IDENTIFICADOR", onde identificador pode ser qualquer string que facilitará a identificação do diretório com as coletas
Exemplo: urls.txt
-------------------
```
https://www.facebook.com/cnn/posts/10154743166271509/beatriz2904
https://www.facebook.com/cnn/posts/10154888483356509/vitoria0706
https://www.facebook.com/cnn/posts/10154892674111509/tiago0806
https://www.facebook.com/cnn/posts/10154959957576509/bia2406
https://www.facebook.com/cnn/posts/10154787199416509/luciana1105
```
  * Execute o script de dentro do diretório corrente
```
perl coleta.pl
```
  * O script coletará os comentários de cada post e os salvará um comentário por arquivo, um diretório por post no diretório "coletas".
