# Produto — ciclo do treino, party e convites

Escrito em 27/09/2026, a partir das decisões do Lucas. Este documento é o
contrato do que o app faz, antes de virar código.

---

## 1. O ciclo de um treino

Três estados, não dois. É a mudança mais importante em relação ao app de hoje.

```
  ABERTO  ──────▶  INICIADO  ──────▶  ENCERRADO
     │                 │
     │                 └── Live Activity ativa, fotos e comentários
     │
     └── aparece no Feed de quem está perto, recebe convites
```

### 1.1 Aberto

A pessoa anuncia que vai treinar: esporte, academia ou local, e quando.
A partir daí ela **aparece para quem está perto** e pode receber convites.

Um treino aberto ainda não começou. É o "estou disponível" de hoje, mas com
identidade própria — ele existe como registro, não como um recado passageiro.

### 1.2 Iniciado

Quando o treino realmente começa, a pessoa inicia. Daí em diante:

- Uma **Live Activity** fica no topo da tela e na Dynamic Island, do jeito
  que o iFood mostra o pedido. A pessoa sai do app e o treino continua lá.
- Os participantes podem **mandar fotos e comentários** dentro do treino.
- O saldo de convite de academia é descontado aqui, se for usado.

### 1.3 Encerrado

Fecha o treino. É o gancho para o que o backlog já pedia: confirmar presença
e avaliar quem treinou junto. Sem esse momento, confiabilidade e avaliação
não têm de onde sair.

---

## 2. Party: treino com mais de duas pessoas

Um treino não é mais um par. É uma **sessão com participantes**.

- Dupla é o caso comum: dois participantes.
- Party é o mesmo treino com limite maior.

Modelar assim desde o começo evita a reescrita que aconteceria se
começássemos com `partnerA` e `partnerB` no banco.

### 2.1 Quantas pessoas — decidido em 27/09

O anfitrião escolhe, entre **2 e 6, com padrão 2**.

**Padrão 2** porque a promessa do app é parceiro, não turma. Abrir já
sugerindo grupo muda o que a pessoa espera do produto na primeira tela.

**Teto 6** não é número mágico: é onde a coisa muda de natureza.

| Até 6 | Acima de 6 |
|---|---|
| Todo mundo se conhece no treino | Vira evento |
| Cabe na Live Activity | Precisa de lista, não de avatares |
| Quem faltou é óbvio | Precisa de chamada e lista de espera |
| Um combina com o outro | Precisa de ferramenta de organizador |

Evento é outro produto. Se um dia fizer sentido, que seja de propósito — e
não por acidente, porque alguém abriu uma party de trinta.

### 2.2 A party esbarra no saldo de convites

Quem abre uma party de 4 **na própria academia** precisa de **3 convites**,
um por visitante. Então o limite real quase nunca é o número escolhido — é o
saldo do mês.

O app precisa dizer isso **na hora de abrir a party**, não no portão da
academia. Quando o treino é na academia do anfitrião e ele tem convites, a
tela de abrir mostra quantos restam e trava o tamanho no que couber.

---

## 3. Convites: dois tipos, que não se confundem

O app tem **duas coisas chamadas convite**, e elas precisam de nomes
diferentes no código para ninguém se perder.

| | O que é | Onde aparece |
|---|---|---|
| **Convite de treino** | "bora treinar comigo?" | Feed e notificações |
| **Convite de academia** | a cortesia que o plano dá | Perfil (o meu), card do Feed (o dos outros) |

### 3.1 Convite de academia — de quem é o que aparece onde

Decisão do Lucas: **no Feed aparecem os convites das outras pessoas.**

Isso muda a natureza da feature. Não é um contador do meu saldo — é a
informação de **quem pode me levar na academia dele**. Vira um motivo a mais
para convidar aquela pessoa e não outra.

O meu próprio saldo fica **no meu perfil**, junto do cadastro do plano.

### 3.2 O saldo zera todo mês — e como fazer isso sem cron

Decisão do Lucas: o saldo acompanha o ciclo do plano.

A forma óbvia seria guardar `invitesAvailable` e zerar todo mês por uma
tarefa agendada. **Não vamos fazer assim.** Tarefa agendada falha calado, e
quando falha o usuário fica sem convite sem entender por quê.

Em vez disso, guardamos:

- `invites_per_month` — quantos o plano dá
- o registro de **cada convite consumido**, com data

E o saldo é **calculado**:

```
disponível = invites_per_month − (consumidos desde o início do ciclo atual)
```

Assim "zera todo mês" acontece sozinho na virada, sem nada rodando. Não tem
como divergir, e ainda sobra o histórico de quando cada convite foi usado.

---

## 4. Cadastro e identidade

Decisão do Lucas: **Sign in with Apple**, com a intenção de amarrar uma conta
a uma pessoa.

### 4.1 O que o Sign in with Apple resolve

Dá um identificador estável por pessoa e por app, sem servidor. É a base.

### 4.2 Decidido em 27/09: CPF e telefone, com o CPF guardado como hash

O Lucas quer os dois, e a decisão é dele. A implementação abaixo entrega o
objetivo — uma conta por pessoa — **sem o banco guardar o número**.

```
CPF digitado → valida dígito verificador no aparelho
             → hash com pepper que só o servidor conhece
             → grava o hash, com índice único
```

O que isso entrega, igual ao pedido:

- uma conta por CPF, garantido pelo índice único
- segunda tentativa com o mesmo CPF é recusada
- número inventado é barrado na validação do dígito

E o que deixa de ser risco:

- **não existe CPF no banco para vazar** — hash com pepper não volta
- um dump do banco não expõe ninguém
- na revisão da App Store dá para afirmar que o documento não é armazenado

**Quando isso não serve:** se um dia for preciso o número de verdade — nota
fiscal, pagamento, consulta em órgão. Aí é outro requisito, e a decisão muda.

**Telefone** entra junto, com verificação por SMS. Os dois somados são mais
fortes que qualquer um sozinho: o CPF garante unicidade, o telefone prova
posse no momento do cadastro.

O pepper **nunca** vai no app. Fica no servidor, e o hash é calculado lá —
senão qualquer um que abrir o binário consegue testar CPFs até achar o de
alguém.

### 4.3 O que pesou contra o CPF, registrado

A intenção é legítima: evitar conta falsa e duplicada num app onde duas
pessoas vão se encontrar pessoalmente. Mas CPF tem três problemas concretos:

1. **Não resolve o que promete.** CPF de parente, de terceiro e listas
   prontas de CPF válido circulam. Quem quer burlar, burla.
2. **Risco de App Store.** A diretriz 5.1.1(v) diz que o app não pode exigir
   dado pessoal que não seja diretamente relevante ao serviço. Pedir CPF para
   achar parceiro de treino é o tipo de coisa que a revisão questiona. Pior:
   o Sign in with Apple existe para *reduzir* o dado que o app vê, então
   pedir CPF logo em seguida é contraditório aos olhos do revisor.
3. **Vira responsabilidade sua.** CPF é dado pessoal sob a LGPD. Junto com
   localização, o vazamento deixa de ser constrangimento e vira risco físico
   para o usuário. Você passa a ter obrigação de proteger, de informar em
   caso de incidente e de apagar quando pedirem.

### 4.4 O que mais protege, além do cadastro

- **Verificação por telefone (SMS).** É o padrão do mercado para "uma conta,
  uma pessoa". Número é mais difícil de reaproveitar que CPF, e o usuário já
  espera ser perguntado.
- **Verificação de documento só quando importa**, como selo de verificado —
  feita por um serviço especializado, que fica com o dado em vez de você.
- **Denúncia e bloqueio.** Na prática é o que mais protege, e já está no
  backlog.

Nada disso some por causa do cadastro. **Denúncia e bloqueio** continuam
sendo o que mais protege na prática, e seguem no backlog.

E valem as regras de sempre: o CPF nunca é exibido a outro usuário, a
política de privacidade diz o que é feito com ele, e vale contar com uma
rodada extra de revisão na App Store.

---

## 5. Esboço do banco

Postgres com PostGIS. Reflete tudo acima.

```sql
create extension if not exists postgis;

-- Perfil, ligado à conta do Sign in with Apple
create table profiles (
  id                 uuid primary key references auth.users,
  name               text not null,
  city               text,
  bio                text,
  gym                text,
  -- Identidade. O CPF nunca é guardado: só o hash, calculado no servidor
  -- com um pepper que não sai de lá. Serve para garantir uma conta por
  -- pessoa sem existir número nenhum para vazar.
  cpf_hash           bytea unique,
  phone              text,
  phone_verified_at  timestamptz,
  location           geography(point, 4326),
  invites_per_month  int not null default 0,
  created_at         timestamptz default now()
);
create index on profiles using gist (location);

-- Um treino. Dupla e party são o mesmo tipo, mudando o limite.
create type workout_status as enum ('open', 'started', 'finished', 'cancelled');

create table workouts (
  id               uuid primary key default gen_random_uuid(),
  host_id          uuid not null references profiles,
  sport            text not null,
  gym              text,
  location         geography(point, 4326),
  status           workout_status not null default 'open',
  -- 2 é dupla, até 6 é party. O teto é regra de produto, não de banco —
  -- ver §2.1 para o porquê de 6.
  max_participants int not null default 2
                   check (max_participants between 2 and 6),
  scheduled_for    timestamptz,
  started_at       timestamptz,
  finished_at      timestamptz,
  created_at       timestamptz default now()
);
create index on workouts using gist (location);
create index on workouts (status) where status = 'open';

create type participant_status as enum ('invited', 'joined', 'declined', 'left');

create table workout_participants (
  workout_id  uuid not null references workouts on delete cascade,
  profile_id  uuid not null references profiles,
  status      participant_status not null default 'invited',
  is_host     boolean not null default false,
  present     boolean,                          -- confirmado ao encerrar
  joined_at   timestamptz,
  primary key (workout_id, profile_id)
);

-- Fotos e comentários dentro de um treino iniciado
create type post_kind as enum ('photo', 'comment');

create table workout_posts (
  id          uuid primary key default gen_random_uuid(),
  workout_id  uuid not null references workouts on delete cascade,
  author_id   uuid not null references profiles,
  kind        post_kind not null,
  body        text,
  photo_path  text,                             -- no Storage, não no banco
  created_at  timestamptz default now()
);

-- Cada convite de academia consumido. O saldo é derivado daqui.
create table gym_invite_uses (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references profiles,
  workout_id  uuid references workouts,
  used_at     timestamptz not null default now()
);
create index on gym_invite_uses (profile_id, used_at desc);
```

### 5.1 O saldo, como consulta

```sql
create or replace function invites_left(p uuid)
returns int language sql stable as $$
  select p2.invites_per_month - count(u.id)::int
    from profiles p2
    left join gym_invite_uses u
      on u.profile_id = p2.id
     and u.used_at >= date_trunc('month', now())
   where p2.id = p
   group by p2.invites_per_month;
$$;
```

Zera na virada do mês sozinho. Nada agendado, nada para falhar.

---

## 6. O que isso exige do app

| Precisa | Por quê |
|---|---|
| **Widget Extension** | Live Activity não roda no target principal |
| **APNs** | A Live Activity é atualizada por push quando o app está fechado |
| **Supabase Storage** | As fotos do treino não vão no banco |
| **Realtime** | Convite e comentário precisam chegar na hora |

---

## 7. Limites do plano gratuito do Supabase

O Lucas pediu para não pagar nada no começo. Dá, com ressalvas — **confirme
os números atuais, eles mudam**:

- Banco pequeno (ordem de centenas de MB) — folgado para texto, apertado para
  qualquer coisa além disso
- **Storage é o gargalo.** Fotos de treino consomem rápido; é o primeiro
  limite que você vai bater
- **O projeto hiberna** depois de alguns dias sem acesso. Em teste com
  amigos, a primeira abertura do dia pode demorar
- Sem backup automático com retenção longa

**Recomendação:** começar no gratuito para validar com pessoas reais, com
duas defesas desde o primeiro dia — **comprimir a foto no aparelho** antes de
subir, e **limitar quantas fotos por treino**. Sem isso o limite chega em
semanas.
