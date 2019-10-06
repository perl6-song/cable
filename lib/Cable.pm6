
unit class Cable is export;

role Message {
    method type(--> Any:U) { ... }

    method id(--> Str) { ... }

    method data() {}

    method process($ret) { ... }
}

role Observer {
    method id(--> Str) { ... }

    method check(Message --> Bool) { True }

    method process(Message) { ... }
}

role Subject {
    has Observer @!observer;

    method attach(Observer $ob) {
        @!observer.push($ob);
    }

    multi method detach() {
        @!observer = [];
    }

    multi method detach(Observer $ob) {
        for @!observer.kv -> $index, $item {
            if $item.id() eq $ob.id() {
                @!observer.slice($index, 1);
                last;
            }
        }
    }

    method notify(Message $msg, :$once)  {
        for @!observer -> $ob {
            if $ob.check($msg) {
                $msg.process(
                    $ob.process($msg)
                );
                last if $once;
            }
        }
    }
}
