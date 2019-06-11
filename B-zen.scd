
s.boot;



(
Ndef(\Bzen, {
			var pan = LFNoise1.kr(\panSpeed.kr(1)).range(-1, 1);
			var input = SoundIn.ar([0,1]);
	        var rev = FreeVerb.ar(input,
			\mix.kr(0.9),
			\room.kr(0.2, 0.5),
		        \damp.kr(0.1, 0.3));
			var sig = PitchShift.ar(input,
				\winSize.kr(0.8, 0.3),
				\pitch.kr(1, 10),
				\pitchDisp.kr(0.01, 0.3),
				\timeDisp.kr(0.01, 0.3) );
			var delay = CombN.ar (sig + rev,
			    \maxdelaytime.kr(0.9, 6), 0.4,
			    \decaytime.kr(5, 9), 2.0);
			sig = Mix.fill(14, {AllpassN.ar(sig, 0.1, 0.1.rand)});
			sig = sig / 14 *  0.5;
			sig = sig.sum;
			Pan2.ar(delay, pan, 1);
	})
)


 Ndef(\Bzen).play;


////////////////////// LEAP CONNECTION ///////////////

		//Control externally with MIDI

(
		MIDIClient.init;
		MIDIIn.connectAll;
		MIDIFunc.trace(false); //test only


        Spec.add(\room, [0.5, 9.0]);
        Spec.add(\damp, [0.4, 10.0]);
	    Spec.add(\maxdelaytime, [1.0, 8.0]);
	    Spec.add(\decaytime, [0.5, 9.0]);
        Spec.add(\pitch, [0.1, 14.0]);
		Spec.add(\pitchDisp, [0.01, 1.5]);
		Spec.add(\timeDisp, [0.01, 1.5]);
		Spec.add(\panSpeed, [0.1, 10]);
	)

(
{
			~sl = ();
			~cs = (\room: \room.asSpec, damp: \damp.asSpec, \maxdelaytime: \maxdelaytime.asSpec, \decaytime: \decaytime.asSpec, pitch: \pitch.asSpec, pitchDisp: \pitchDisp.asSpec, timeDisp: \timeDisp.asSpec, panSpeed: \panSpeed.asSpec);

			w = Window.new("grains | freqScope", 550@430).front;
			~freqScope = FreqScopeView.new(w, Rect(1, 350, 560, 80), s);
			~serverMeter = ServerMeterView(s, w, Point(400, 20), 1, 2);
			~freqScope.active_(true);
			~freqScope.freqMode_(1);
			w.view.decorator = f = FlowLayout.new( w.view.bounds, 10@10, 20@5);
			NdefGui(Ndef(\Bzen), 7, w);

			[\room, \damp, \maxdelaytime, \decaytime, \pitch, \pitchDisp, \timeDisp, \panSpeed].do({|par|
				~sl[par] = EZSmoothSlider(w, 380@30, par, ~cs[par], Routine { |sl|
					var newVal, lastVal;
					loop {
						newVal = sl.value;
						Ndef(\Bzen).softSet(par, newVal.lag, 0.025, lastVal: lastVal, spec:~cs[par]);
						lastVal = newVal;
						\dummy.yield;
					}
				}).setColors(Color.grey(0.3), Color.grey(0.7), Color.grey(alpha:0.8))
			});

			w.onClose_({ ~freqScope.kill; ~serverMeter.remove; x.free; ~midifunc.free });

		}.defer;
)

(
           ~cc = (1: \room, 2:\damp, 3:\maxdelaytime, 4:\decaytime, 5:\pitch, 6:\pitchDisp, 7:\timeDisp, 8:\panSpeed);

			~midifunc = MIDIdef.cc(\akaiKnobs, {|val, num|
				{ ~sl[ ~cc[num] ].valueAction_(~sl[ ~cc[num] ].controlSpec.map(val/127)) }.defer
			}, (1..8) );//midi knobs 1 - 8.
)

