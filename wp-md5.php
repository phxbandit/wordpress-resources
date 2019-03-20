<!DOCTYPE html>
<html>
<head>
<title>wp-md5.php - WordPress core file integrity checker</title>
<meta charset="UTF-8">
</head>
<body>

<h3>wp-md5.php - WordPress core file integrity checker</h3>

<?php

function path_form() {
    echo "<form method=\"POST\">\n";
    echo "<p>Enter the absolute path to WordPress</p>\n";
    echo "<p><input type=\"text\" name=\"path\" /></p>\n";
    echo "<p><input type=\"submit\" name=\"check\" value=\"Check\" /></p>\n";
    echo "</form>\n\n";
}

function find_wp_version($path) {
    $wp_path = preg_replace('/\/$/', '//', $path);
    $version_php = "$wp_path/wp-includes/version.php";
    $about_php = "$wp_path/wp-admin/about.php";

    if ( file_exists($version_php) ) {
        $fh = fopen($version_php, 'r') or die("ERROR: Cannot read $version_php\n");
        while ( $line = fgets($fh) ) {
            // $wp_version = '5.1.1';
            if ( preg_match("/wp_version = '([\d.]+)'/", $line, $ver_match) ) {
                $wp_ver = $ver_match[1];
            }
        }
    } elseif ( file_exists($about_php) ) {
        $fh = fopen($about_php, 'r') or die("ERROR: Cannot read $about_php\n");
        while ( $line = fgets($fh) ) {
            // sanitize_title( '5.1.1' )
            if ( preg_match("/sanitize_title\( '([\d.]+)'/", $line, $ver_match) ) {
                $wp_ver = $ver_match[1];
            }
        }
    } else {
        echo "ERROR: WordPress version not found<br>\n";
        close_html();
        exit(1);
    }

    fclose($fh);
    echo "Found WordPress version <strong>$wp_ver</strong> at $wp_path<br><br>\n";
    return array($wp_ver, $wp_path);
}

function compare_hashes($wp_ver, $wp_path) {
    $response = file_get_contents("https://api.wordpress.org/core/checksums/1.0/?version=$wp_ver&locale=en_US");
    $sum_array = json_decode($response, true);
    
    foreach ($sum_array['checksums'] as $key => $value) {
        $ref_file = $key;
        $installed_file = "$wp_path/$ref_file";
        $ref_hash = $value;
        $installed_hash = md5_file($installed_file);
        
        if ($ref_hash != $installed_hash) {
            echo "ALERT: MD5s for <strong>$ref_file</strong> do not match<br>\n";
            echo "Reference file : $ref_hash<br>\n";
            echo "Installed file : $installed_hash<br><br>\n";
        }
    }
}

function close_html() {
    echo "\n<h5><a href=\"https://github.com/phxbandit/\">github.com/phxbandit</a></h5>\n\n";
    echo "</body>\n";
    echo "</html>";
}

function main() {
    path_form();

    if ( isset($_POST['check']) && isset($_POST['path']) ) {
        if ( preg_match('/^\//', $_POST['path']) ) {
            $path = $_POST['path'];
            $wp_attr = find_wp_version($path);
        } else {
            echo "ERROR: Path must be absolute<br>\n";
            close_html();
            exit(1);
        }
    } else {
        close_html();
        exit(1);
    }

    // compare_hashes($wp_ver, $wp_path);
    compare_hashes($wp_attr[0], $wp_attr[1]);

    close_html();
}

/**********************************************************/

main();

?>