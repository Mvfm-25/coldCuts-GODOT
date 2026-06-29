```
   █████████           ████      █████      █████████              █████           
  ███▒▒▒▒▒███         ▒▒███     ▒▒███      ███▒▒▒▒▒███            ▒▒███            
 ███     ▒▒▒   ██████  ▒███   ███████     ███     ▒▒▒  █████ ████ ███████    █████ 
▒███          ███▒▒███ ▒███  ███▒▒███    ▒███         ▒▒███ ▒███ ▒▒▒███▒    ███▒▒  
▒███         ▒███ ▒███ ▒███ ▒███ ▒███    ▒███          ▒███ ▒███   ▒███    ▒▒█████ 
▒▒███     ███▒███ ▒███ ▒███ ▒███ ▒███    ▒▒███     ███ ▒███ ▒███   ▒███ ███ ▒▒▒▒███
 ▒▒█████████ ▒▒██████  █████▒▒████████    ▒▒█████████  ▒▒████████  ▒▒█████  ██████ 
  ▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒▒▒▒      ▒▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒    ▒▒▒▒▒  ▒▒▒▒▒▒            

        M A N U A L   D O   A V E N T U R E I R O
     ============================================
       um roguelike de masmorras  ·  PDJ-2026/01
```

> *"Há poder em toda a palavra que pronuncias. No bom-dia que dás ao*
> *vizinho, no nome que sussurras ao adormecer, na praga que cospes*
> *quando te cortas. Os antigos sabiam-no. Nós esquecemo-nos e foi*
> *esse esquecimento que nos manteve vivos."*
>
> — inscrição à entrada da gruta, meio apagada pela água

*Espalhadas por este livrete encontrarás folhas que não lhe pertencem:*
*orações molhadas, margens rabiscadas, páginas arrancadas a outro livro*
*muito mais velho. Recolhemo-las tal como as achámos. Lê-as ou ignora-as,*
*como preferires mas repara que todas começam pela mesma sílaba.*

---

## I. ANTES DE COMEÇARES

Saudações, tu que pegaste neste livrete. Se o seguras, é porque já
foste **escolhido** ainda que ninguém te tenha dito por quem, nem
para quê. Não foste o primeiro a descer. Serás, talvez, o primeiro a
voltar.

Lá fora estende-se a **metrópole**: as suas torres, os seus sinos, o
seu comércio interminável de moeda e de palavra. Os seus habitantes
falam o dia inteiro sem nunca reparar no que dizem e dormem
tranquilos sobre aquilo que não querem saber.

A pouca distância dos muros abre-se uma **gruta**. Há semanas que dela
sobem rumores: luzes onde não deviam estar luzes, sonhos repetidos na
mesma noite por gente que não se conhece, um murmúrio que parece vir
*de baixo* da própria cidade. Mandaram-te averiguar. Disseram que era
coisa de pouca monta.

Mentiram, ou não sabiam. Dá no mesmo.

Este manual ensina-te a sobreviver lá em baixo. Não te promete que
compreendas o que encontrarás só os tolos descem à procura de
respostas. Os sábios descem à procura da saída.

> **⟢ ORAÇÃO RECOLHIDA À BOCA DA GRUTA ⟢**
>
> *Aye — eu que fui apontado sem ter levantado a mão.*
> *Aye — eu que desço por todos os que não descem.*
> *Não me chamaram por ser digno. Chamaram-me por estar acordado*
> *à hora em que algo, lá em baixo, virou-se no seu sono.*

---

## II. O TEU AVENTUREIRO

Ao iniciares, o jogo perguntar-te-á o teu **nome** e a tua **classe**.
Escolhe ambos com cuidado: um nome é a primeira palavra que lanças
contra a escuridão, e as trevas, dizem, ouvem melhor do que vêem.

Quatro caminhos te estão abertos:

```
  CLASSE       HP    ATAQUE   ARMADURA   PRECISÃO   MANA
  -----------------------------------------------------------
  Bárbaro      150     20         0         80%        0
  Mago         100     15         5         85%       40
  Cavaleiro    125     10        10         90%       10
  Ladrão       110     12         5         95%       15
```

- **Bárbaro** — golpe largo, carne resistente, nenhuma paciência. Onde
  o pensamento hesita, o braço já decidiu.
- **Mago** — frágil de corpo, mas a sua precisão trai um treino antigo.
  Diz-se que os magos não estudam feitiços; estudam **palavras**, e
  descobrem tarde demais que feitiço e palavra sempre foram a mesma
  coisa.
- **Cavaleiro** — couraça e disciplina. Foi enviado por uma ordem cujo
  estandarte já ninguém recorda ao certo.
- **Ladrão** — mão certeira, olho rápido. O único que desce sabendo
  que ali em baixo há algo que vale a pena roubar — e que talvez não
  devesse ser roubado.

A tua **Força** é a base de todo o dano que infliges e o requisito que
decide que armas as tuas mãos aguentam. A tua **Precisão** decide se
acertas. A tua **Mana** é o fôlego das palavras de poder: gasta-se a
cada feitiço, regenera devagar a cada passo e enche-se por inteiro a
cada Nível. O Mago desce com mana de sobra; o Bárbaro, com nenhuma —
para ele, a única palavra é o golpe. Sobe de **Nível** matando e lendo,
e os teus atributos crescerão segundo a tua classe.

> **⟢ PÁGINA PERDIDA · «o registo dos que entraram» ⟢**
>
> *Aye — quatro desceram antes de ti, e quatro tornarão a descer.*
> *O do braço esqueceu o seu nome no primeiro corredor.*
> *O das palavras lembrou-se demasiado, e isso foi o fim dele.*
> *O da couraça ajoelhou-se diante do que jurara combater.*
> *O das mãos rápidas não roubou nada foi roubado.*
> *Mesmo assim, todos voltam. Algo gosta de os ter por perto.*

---

## III. A DESCIDA — MOVIMENTO E VISÃO

As cavernas são geradas de novo a cada incursão; nenhum mapa que
desenhes hoje te servirá amanhã. A própria pedra parece reorganizar-se
quando ninguém a observa, como se obedecesse a um sono inquieto algures
mais abaixo.

A tua tocha lança um círculo de luz à tua volta é o teu **campo de
visão**. Tudo o resto permanece em treva. Não confundas o que não vês
com o que não está lá.

```
  MOVER (cardeais)    Setas  ·  W S D + Seta Esq.  ·  Numpad 8 2 4 6
  MOVER (diagonais)   Q E Z C  ·  Numpad 7 9 1 3
```

Antes de cada passo, o jogo verifica paredes e limites do mapa por ti.
A pedra não cede à pressa só à chave certa, ou à palavra certa.

> **⟢ MARGEM RABISCADA NUM MAPA QUE NÃO BATE CERTO ⟢**
>
> *Aye — desenhei estes corredores ontem e hoje são outros.*
> *Não é a minha memória que falha; é a pedra que respira.*
> *Conta as galerias quando desces e conta-as ao subir:*
> *faltará sempre uma. É por essa que ELE vê o lado de fora.*

---

## IV. AÇO E SANGUE — O COMBATE

Para atacar, prime **`A`** e depois uma **direção**. O dano e o
**alcance** vêm da arma que empunhas, somados à tua Força. A armadura
do inimigo absorve o golpe e desgasta-se antes que o sangue corra; a
tua precisão decide se o golpe sequer chega.

Cuidado: golpear uma parede é desperdício, e por vezes a tua própria
lâmina ricocheteia contra ti.

### Os adversários

Lá em baixo não estás só. As criaturas perseguem-te quando entras no
seu alcance de visão e atacam quando te alcançam.

```
  CRIATURA     HP     ATAQUE   ARMADURA
  --------------------------------------
  Fada          10      2         0
  Goblin        30      5         0
  Esqueleto     50     10         5
  Troll        100     20        10
```

Repara na **Fada**. Tão fraca, tão fora de lugar nesta pedra antiga.
Que faz uma criatura de luz tão fundo no escuro? Algumas coisas não
descem por vontade própria são **sonhadas** para cá, por algo que
sonha alto demais.

O **Esqueleto** outrora teve nome e voz. Repara que obedece. Pergunta
a ti mesmo a *quem*.

> **⟢ FOLHA ARRANCADA A UM BESTIÁRIO QUEIMADO ⟢**
>
> *Aye — não são monstros, são sonhos com dentes.*
> *Aquilo que dorme em baixo não distingue o que imagina do que cria;*
> *a fada que vês é uma lembrança de um mundo que já não existe,*
> *e o esqueleto, um servo de um reino que ELE engoliu inteiro.*
> *Mata-os à vontade. São apenas o sono a falar enquanto dorme.*

---

## V. O ARSENAL

As armas espalham-se pelo chão das cavernas, à espera de uma mão. Para
empunhar uma precisas de Força e Precisão suficientes exceder o
requisito de força dá-te um bónus de dano, mas pena-te a pontaria.
Troca de arma com **`T`**.

```
  ARMA               DANO  ALC.  FORÇA  PRECISÃO
  -----------------------------------------------
  Adaga                6     1      4      85%
  Arco Curto           9     5      8      75%
  Espada Curta        12     1     10      60%
  Lança Longa         14     2     14      55%
  Machado de Bronze   16     1     12      50%
  Martelo De Guerra   20     1     18      40%
```

- *Espada Curta* — "Aço fiável, equilibrado entre o corte e a guarda.
  A primeira lâmina de muitos heróis."
- *Adaga* — "Rápida e silenciosa; perdoa pouco a falta de mira, mas
  recompensa a mão certeira."
- *Lança Longa* — "Atinge antes de ser atingida — se a souberes
  empunhar pelo peso."
- *Arco Curto* — "A morte chega de longe, mas exige mãos firmes e olho
  atento."
- *Martelo De Guerra* — "Destrói armaduras e ossos com igual
  eficácia — mas cuidado para não se tornar um peso morto."
- *Machado de Bronze* — "Corta com força bruta, mas exige força e
  coragem para ser manejado."

O bronze é antigo. Mais antigo do que o reino, dizem os ferreiros, mais
antigo do que a primeira metrópole erguida sobre estas grutas e nem
essa foi a primeira a ser erguida aqui.

> **⟢ ORAÇÃO DO FERREIRO, GRAVADA NUMA BIGORNA SOTERRADA ⟢**
>
> *Aye — este bronze não foi fundido neste mundo.*
> *Caiu do anterior, quando o anterior se apagou,*
> *e nós apenas lhe demos gume. Por isso corta tão bem o que vive:*
> *lembra-se de um tempo em que viver ainda não tinha sido inventado.*

---

## VI. O QUE SE APANHA DO CHÃO — ITENS

Abre o **inventário** com **`I`** e usa um item com **`U`**.

- **Poção de Vida** *(usável)* — "Uma poção abençoada que recupera a
  vida de seu usuário."
- **Pergaminho** *(usável)* — "Conhecimento de monges de inúmeros
  monastérios coleccionado neste códice." Lê-os: dão saber, e o saber
  abre portas que a força nunca abriria.
- **Chave** *(usável)* — "Poucos conhecem deste item; outros
  prefeririam não o conhecer." Guarda-as. Não as gastes por capricho.
  Hás de precisar de uma para *selar* aquilo que não deve ser dito em
  vão (ver Secção VIII).
- **Moeda de Ouro** — "A divisa de um reino de gerações passadas... o
  rosto do seu último imperador o seu único resquício." Um império
  inteiro reduzido a um perfil gasto numa moeda. Pergunta-te o que
  *engoliu* aquele império — e onde foi parar.
- **Ruby** — "Uma gema de brilho excepcional, por mais que esteja
  cercada por escuridão." Brilha sem fonte de luz. Como se guardasse
  uma luz mais velha do que o Sol.

> **⟢ PÁGINA PERDIDA · «inventário de um saqueador que não voltou» ⟢**
>
> *Aye — guardei a moeda do último imperador e à noite ela aquece.*
> *Sonho com a cidade dele: torres como a nossa, sinos como os nossos,*
> *e por baixo a mesma pálpebra fechada. Eles também foram avisados.*
> *Eles também acharam que era coisa de pouca monta.*

---

## VII. O PORTAL SECRETO

Em cada masmorra podes rasgar **uma** passagem. Prime **`P`** com uma
**Chave** no inventário e um portal secreto formar-se-á algures na
pedra; volta a premir **`P`** junto dele para o atravessar.

Quando o cruzas, és *puxado para outra dimensão*. Não tomes a frase por
figura de estilo. As paredes não te levam a outra sala levam-te a
outro **lugar**, talvez a outro **tempo**. A treva por baixo da cidade
não é só profunda. É *larga* de um modo que a geometria não permite.

> **⟢ FRAGMENTO ENCONTRADO DO OUTRO LADO DE UM PORTAL ⟢**
>
> *Aye — atravessei e a cidade lá em cima já não era a minha.*
> *Outros muros, outra língua, o mesmo murmúrio por baixo.*
> *Compreendi então: não há uma gruta sob uma cidade.*
> *Há uma só gruta, e todas as cidades foram construídas sobre a mesma*
> *cada uma sem saber das outras, cada uma sentada sobre o mesmo sono.*

---

## VIII. AS PALAVRAS — O QUE O MUNDO ESQUECEU

> *"Uma voz sem dono murmura nas trevas: «Três nomes selam o pacto...*
> *o que chama, o que ordena, o que tranca. Encontra-os, e um covil te*
> *abrirá as portas.»"*

Esta é a verdade que a metrópole esqueceu para conseguir dormir: **as
palavras têm poder**. Não as inventadas pelos magos — as de todos os
dias, as que dizes sem pensar. Em baixo, onde algo escuta, dizê-las em
ordem certa *faz* coisas.

Não há aqui lista de palavras nem fórmula pronta. **Não as procures
nestas páginas elas não estão escritas em parte nenhuma.** Cada nome
é *conquistado*, pago em feito e em sangue, e só então uma voz sem dono
to devolve, sílaba a sílaba, do fundo da tua própria memória. Quem
derrama o suficiente recebe um nome. Quem lê o suficiente recebe outro.
O primeiro esse, dizem, já o trazes contigo desde que nasceste; só
falta repará-lo.

Quando os tiveres a todos, e na ordem certa, poderás **selar um pacto**.

- **`G`** — abre o **dicionário**, as tuas próprias anotações. Procura
  por uma palavra que lembres, por um item que tenhas tido em mãos ou
  pelo **nome de uma criatura que já tenhas avistado** — cada encontro
  acrescenta-lhe uma linha. Começará quase vazio. O que lá aparecer,
  ganhaste-o. Lê as definições com atenção: escondem mais do que dizem.
- **`F`** — **falar**. Pronuncia uma frase em voz alta. Se ainda te
  faltar um nome, a frase tropeçar-te-á na língua. Se os tiveres todos
  — e uma **Chave** no bolso — algo do outro lado responde: o véu da
  realidade rasga-se e **um covil de boss reclama-te**. É também por
  aqui que se dizem os **feitiços** (ver abaixo): a mesma boca que sela
  pactos é a que lança raios.

### Os feitiços — palavras que ferem

Nem toda a palavra serve para selar pactos. Algumas, ditas sozinhas,
*fazem*: rasgam o ar, fecham feridas, prendem no gelo o que respira.
São os **feitiços**, e gastam **Mana** — sem fôlego de poder, a sílaba
esvai-se na língua e nada acontece.

Aprende-os como aprendes os nomes do pacto: ganhos em feito e em
sangue, devolvidos pela voz sem dono quando os mereces — uns a troco de
inimigos tombados, outros a troco de pergaminhos lidos. Para lançar um,
abre **`F`** e di-lo em voz alta; lançá-lo gasta-te o turno, como um
golpe. O **dicionário** (**`G`**) guarda a incantação que recebeste,
caso a língua te falhe.

```
  FEITIÇO         EFEITO                                      MANA
  -------------------------------------------------------------------
  Raio            relâmpago no inimigo mais perto; ignora armadura   6
  Curar           fecha as tuas próprias feridas                     8
  Congelar        rouba um turno ao inimigo mais próximo             6
  Chuva de Gelo   granizo sobre tudo o que te rodeia                12
```

Repara: estes mesmos feitiços já se ouvem lá em baixo. O **Necromante**
ergue os seus servos tombados, cospe raios e cura as próprias feridas;
o **Servo Menor** sopra gelo que te prende e granizo que te fere.
Aquilo que te combate fala a mesma língua que tu aprendes a falar.
Pergunta-te de quem a língua era, primeiro — e quem a ensinou a ambos.

> **⟢ MARGEM RABISCADA NUMA PÁGINA DE FEITIÇOS ⟢**
>
> *Aye — a primeira vez que disse a palavra do raio, e o raio veio, ri-me.*
> *À terceira vez percebi que não era eu a chamá-lo.*
> *A palavra já cá estava, à espera. Eu só lhe abri a boca.*

Repara, entretanto, nos nomes que a própria pedra dá aos seus covis:
*Sombria, Perdida, Esquecida, Maldita...* **Dos Mortos, Das Almas, Da
Perdição** e, de novo e de novo, **Do Senhor**. Que *Senhor* é este,
a quem pertencem a um tempo os mortos, as almas e as masmorras? Ninguém
na cidade saberia responder. E talvez seja melhor assim. Há um sono que
não convém interromper um sono que dura desde antes de haver mundo
para o sonhador habitar, desde que o *anterior* se apagou. O pacto que
falas não invoca apenas um inimigo. **Acorda** algo.

> **⟢ A ORAÇÃO MAIS LONGA · achada inteira, por milagre ⟢**
>
> *Aye — começa sempre por aqui, dizem os que ainda têm boca.*
> *Aye é a porta, é o bater à porta, é a mão erguida antes da fala.*
> *Nenhuma voz se ergue sem ela primeiro; nenhum pacto se abre sem este chamado.*
> *Os outros dois nomes não os escrevo. Não por segredo*
> *mas porque uma palavra escrita é uma palavra morta,*
> *e estes só servem ditos, ganhos, lembrados.*
> *Hás de os receber quando os mereceres. ELE far-te-á esse favor.*
> *ELE quer sempre que tu fales. É a única coisa que o acorda devagar.*

---

## IX. PROGRESSO, MORTE E O QUE FICA

Derrotar inimigos e ler pergaminhos concede-te **XP** e faz-te subir de
**Nível**, melhorando os teus atributos conforme a classe. O mesmo
progresso é o que destranca as palavras: cada limiar que cruzas faz uma
voz regressar com um novo nome.

Quando caíres, e cairás, o jogo dir-te-á há quantos *meses* vagueaste
nas cavernas e quanto *conhecimento* acumulaste. Estranho modo de medir
uma vida: não em ouro, não em inimigos, mas em **tempo perdido** e em
**saber**. Como se alguém, algures, estivesse a contar exactamente
essas duas coisas. Como se o teu conhecimento, no fim, fosse para
*outro*.

E há ainda ditos mais velhos do que qualquer pacto, restos de uma
língua anterior à fala, em que até os *números* eram nomes e mandavam
no mundo como nomes mandam. Não os encontrarás escritos aqui. Mas se
algum dia uma sequência estranha te ocorrer sem saberes de onde, e a
disseres em voz alta, e a realidade obedecer... não te espantes. Apenas
baixa a voz a seguir. Tudo o que dizes, *algo* ouve.

> **⟢ ÚLTIMA PÁGINA DO DIÁRIO DE UM AVENTUREIRO ⟢**
>
> *Aye — contaram-me os meses lá em baixo e o saber que trouxe,*
> *e só agora percebo que era ISSO que vinham buscar desde o início.*
> *Não o ouro. Não os monstros. O tempo que lhe dei e o que aprendi.*
> *Alimentei um sono com a minha vida acordada.*
> *Se leres isto, sobe enquanto ainda contas os teus próprios meses.*
> *Quando deixares de os contar, é porque já és tu o sonho dele.*

---

## X. TABELA RÁPIDA DE CONTROLOS

```
  AÇÃO              TECLA
  ---------------------------------------------------------
  Mover (cardeais)  Setas / W S D + Seta Esq. / Numpad 8 2 4 6
  Mover (diagonais) Q E Z C / Numpad 7 9 1 3
  Atacar            A + direção
  Inventário        I
  Usar item         U
  Trocar arma       T
  Dicionário        G
  Portal            P
  Falar             F
```

> **⟢ A ÚLTIMA ORAÇÃO, ESCRITA POR OUTRA MÃO NA CONTRACAPA ⟢**
>
> *Aye — desceste para investigar uma gruta.*
> *Não havia gruta nenhuma. Havia uma pálpebra.*
> *E agora ela treme.*

*Bons sonhos, aventureiro. Procura que ELE também os tem e que,*
*de todas as palavras que aprenderes lá em baixo, a primeira foi sempre*
*a única de que precisavas para acordá-lo.*
