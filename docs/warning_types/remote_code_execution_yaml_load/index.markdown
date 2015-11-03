As seen in [CVE-2013-0156](https://groups.google.com/d/topic/rubyonrails-security/61bkgvnSGTQ/discussion), calling `YAML.load` with user input can lead to remote execution of arbitrary code. (To see a real point-and-fire exploit, see the [Metasploit payload](https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/multi/http/rails_xml_yaml_code_exec.rb)). While upgrading Rails, disabling XML parsing, or disabling YAML types in XML request parsing will fix the Rails vulnerability, manually passing user input to `YAML.load` remains unsafe.

For example:

    #Do not do this!
    YAML.load(params[:file])
