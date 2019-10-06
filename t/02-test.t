
use Test;
use Cable;

plan 6;

class ArgumentList does Cable::Message {
    has Str @.data;
    has Int $.index;

    submethod TWEAK(:@data) {
        @!data = @data;
        $!index = 0;
    }

    method id() {
        "arg" ~ $!index;
    }

    method type() {
        self.WHAT;
    }

    method elems() {
        +@!data;
    }

    method index() {
        $!index;
    }

    method current() {
        @!data[$!index];
    }

    method end() {
        $!index >= +@!data;
    }

    method next() {
        @!data[$!index + 1];
    }

    method process(Int:D $ret) {
        for ^$ret {
            $!index += 1;
        }
    }
}

class Parser does Cable::Subject {
    method parse(ArgumentList $al) {
        while ! $al.end() {
            self.notify($al);
        }
    }
}

class IntOpt does Cable::Observer {
    has $.name is required;
    has $.value;

    method id() { "Int" ~ $!name; }

    method check($msg) {
        ($msg.current eq "-{$!name}")
        &&
        (! $msg.end)
        &&
        (so try $msg.next.Int);
    }

    method process($msg) {
        say "Int Option {$!name} set -> \{{$msg.next()}\}";
        $!value = $msg.next().Int;
        return 2;
    }
}

class StrOpt does Cable::Observer {
    has $.name is required;
    has $.value;

    method id() { "Str" ~ $!name; }

    method check($msg) {
        ($msg.current() eq "-{$!name}")
        &&
        (! $msg.end())
        &&
        (! so try $msg.next.Int);
    }

    method process($msg) {
        say "Str Option {$!name} set -> \{{$msg.next()}\}";
        $!value = $msg.next().Str;
        return 2;
    }
}

class BoolOpt does Cable::Observer {
    has $.name is required;
    has $.value;

    method id() { "Bool" ~ $!name; }

    method check($msg) {
        ($msg.current() eq "-{$!name}");
    }

    method process($msg) {
        say "Boolean Option {$!name} set -> \{True\}";
        $!value = True;
        return 1;
    }
}

class NonOpt does Cable::Observer {
    has $.name is required;
    has $.index is required;
    has $.value;

    method id() { "NonOpt" ~ $!name ~ ":" ~ $!index; }

    method check($msg) {
        return $msg.current() eq $!name;
    }

    method process($msg) {
        say "Non Option {$!name}:{$!index} set";
        $!value = $msg.current();
        return 1;
    }
}

my $parser = Parser.new();

$parser.attach( my $c = IntOpt.new(name => "c") );
$parser.attach( my $d = IntOpt.new(name => "d") );
$parser.attach( my $b = StrOpt.new(name => "b") );
$parser.attach( my $a = BoolOpt.new(name => "a") );
$parser.attach( my $m = NonOpt.new(name => "minus", index => 0) );
$parser.attach( my $s = NonOpt.new(name => "string", index => 1) );

$parser.parse(
    ArgumentList.new(data => ["minus", "-a", "-c", "89", "-b", "Str", "-d", "34", "string"])
);

is $c.value, 89, "set c to 89 ok";
is $d.value, 34, "set d to 34 ok";
is $b.value, "Str", "set b to Str ok";
is $a.value, True, "set a to True ok";
is $m.value, "minus", "set m to minus ok";
is $s.value, "string", "set s to string ok";
