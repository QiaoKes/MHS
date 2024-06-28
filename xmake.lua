add_rules("mode.debug", "mode.release")

local project_dir = os.projectdir()

rule("install_deps")
    before_build(function (target)
        function install_meojson_deps()
            local download_url = "https://github.com/MistEO/meojson.git"
            local download_dir = project_dir .. "/tmp/meojson"
            local install_dir = project_dir .. "/3party/meojson"
            local branch = "master"

            if os.exists(install_dir) then 
                return
            end
            os.mkdir(install_dir)

            import("devel.git")
            git.clone(download_url, {depth = 1, branch = branch, outputdir = download_dir})

            os.cp(download_dir .. "/include/*", install_dir)
            os.rmdir(download_dir)
        end

        function install_maafarmework_deps()
            local version = "v1.8.7"
            local file_sha256 = "d4e1c5b028f1a4eb62cf076b059069ef686c2e6820898ba623c8908b241bcd78"

            import("net.http")
            import("utils.archive")

            local url = string.format("https://github.com/MaaXYZ/MaaFramework/releases/download/%s/MAA-win-x86_64-%s.zip", version, version)
            local download_dir = project_dir .. "/tmp"
            local package_file = string.format("%s/MAA-win-x86_64-%s.zip", download_dir, version)
            local install_dir = project_dir .. "/3party/"
            local extract_dir = install_dir .. "/maa"

            if os.exists(extract_dir) then 
                return
            end

            os.mkdir(download_dir)

            if not os.isfile(package_file) then
                -- attempt to remove package file first
                os.tryrm(package_file)
                http.download(url, package_file)

                -- check hash
                if file_sha256 ~= hash.sha256(package_file) then
                    raise("unmatched checksum, current hash(%s) != original hash(%s)", hash.sha256(package_file):sub(1, 8), file_sha256:sub(1, 8))
                end
            end

            -- extract package file
            os.rm(extract_dir)
            os.mkdir(extract_dir)
            if not archive.extract(package_file, extract_dir) then
                os.tryrm(download_dir)
                raise("download maaframework failed!")          
            end
            os.tryrm(download_dir)
        end

        install_meojson_deps()
        install_maafarmework_deps()
    end)

target("MHS")
    -- 二进制编译
    set_kind("binary")

    -- 安装依赖
    add_rules("install_deps")

    -- 添加maa头文件
    add_includedirs("3party")
    add_includedirs("3party/maa/include")
    add_includedirs("3party/maa/binding/cpp/include")

    -- 添加maa lib库
    add_linkdirs("3party/maa/lib")
    add_links("MaaFramework", "MaaToolkit")
    
    add_files("source/*.cpp")
    set_languages("c++23")

   