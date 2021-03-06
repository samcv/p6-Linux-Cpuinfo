use v6.c;

use Linux::Cpuinfo::Cpu;

=begin pod

=begin NAME

Linux::Cpuinfo - Object Oriented Interface to /proc/cpuinfo

=end NAME

=begin SYNOPSIS

=begin code

  use Linux::Cpuinfo;

  my $cpuinfo = Linux::Cpuinfo.new();

  my $cnt  = $cpuinfo.num_cpus();   # > 1 for an SMP system

  for $cpuinfo.cpus -> $cpu {
     say $cpu.bogomips;
  }

=end code

=end SYNOPSIS

=begin DESCRIPTION

On Linux systems various information about the CPU ( or CPUs ) in the
computer can be gleaned from C</proc/cpuinfo>. This module provides an
object oriented interface to that information for relatively simple use
in Perl programs.

=end DESCRIPTION

=begin METHODS

=end METHODS

=end pod

class Linux::Cpuinfo:ver<0.0.7>:auth<github:jonathanstowe> {
    has Str $.filename = '/proc/cpuinfo';
    has Linux::Cpuinfo::Cpu @.cpus;
    has Int $.num-cpus;
    has Str $.arch = $*KERNEL.hardware;
    has $.cpu-class;

    #| Returns an L<doc:Array> of objects of a sub-class of L<doc:Linux::Cpuinfo::Cpu>
    #| that contain the details of each cpu core in the system.  This may be more than
    #| the physical cores in the processor chip(s) if the processor has some mechanism
    #| such as "hyper-threading".
    method cpus() {
        if not @!cpus.elems > 0 {
            my Buf $buf = Buf.new;

            my $proc = open $!filename, :bin;
            my Bool $last = False;

            while not $last {
                my $tmp_buf = $proc.read(1024);
                $last = $tmp_buf.elems < 1024;
                $buf ~= $tmp_buf;
            }

            my $proc_str = $buf.decode;

            for $proc_str.split( /\n\n/ ) -> $cpu {
                if $cpu.chars > 0 {
                    my $co = self.cpu-class.new($cpu);

                    # It seems that single core arm6 or 7 cores highlight
                    # a bug where there is a spurious \n in there
                    # The alert will correctly surmise this breaks for assymetric cpus

                    if @!cpus.elems > 0 and @!cpus[*-1].fields.elems != $co.fields.elems {
                        @!cpus[*-1].fields.push($co.fields.pairs);
                    }
                    else {
                        @!cpus.push($co);
                    }
                }
            }
        }
        @!cpus;
    }

    #| Build a sub class of Linux::Cpuinfo::Cpu
    method cpu-class() {
        if not $!cpu-class.isa(Linux::Cpuinfo::Cpu) {
            my $class-name = 'Linux::Cpuinfo::Cpu::' ~ $!arch.tc;
            $!cpu-class := Metamodel::ClassHOW.new_type(name => $class-name);
            $!cpu-class.^add_parent(Linux::Cpuinfo::Cpu);
            $!cpu-class.^compose;
        }
        $!cpu-class;
    }

    method cpu_class() {
        DEPRECATED('cpu-class', v0.0.7);
        self.cpu-class;
    }

    #| Returns the number of CPU cores reported by the kernel.
    #| This may be the number of "virtual cores" if the CPU
    #| has a mechanism such as "hyper-threading"
    method num-cpus() returns Int {
        if not $!num-cpus.defined {
            $!num-cpus = self.cpus.elems;
        }
        $!num-cpus;
    }

    method num_cpus() returns Int {
        DEPRECATED('num-cpus', v0.0.7);
        self.num-cpus;
    }
}
# vim: expandtab shiftwidth=4 ft=perl6
