workflow HelloWorld {

	call WriteGreeting

	call ReadItBackToMe {
		input:
			original_greeting = WriteGreeting.out
	}

	output {
		File outfile = ReadItBackToMe.outfile
	}
}

task WriteGreeting {

	String greeting

	command {
		echo "${greeting}"
	}

	output {
		String out = read_string(stdout())
	}

	runtime {
		docker: 'debian:stable-slim'
		preemptible: 3
		memory: '1G'
		cpu: 1
	}
}

task ReadItBackToMe {

	String original_greeting

	command {
		echo "${original_greeting} to you too"
	}

	output {
		File outfile = stdout()
	}

	runtime {
		docker: 'debian:stable-slim'
		preemptible: 3
		memory: '1G'
		cpu: 1
	}
}
