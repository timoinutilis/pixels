<?php

require 'autoload.php';
 
define("LCC_IMAGE_WIDTH", 640);
define("LCC_IMAGE_HEIGHT", 360);

$lccPostId = $_GET["lccpost"];
$lccUserId = $_GET["lccuser"];
$lccPost = NULL;
$lccUser = NULL;
$lccUserPosts = NULL;


// Unregister 3 Periodic Footer Widget Sidebars
function twelve14_remove_sidebar() {
      unregister_sidebar( 'sidebar-1' ); 
}
add_action( 'widgets_init', 'twelve14_remove_sidebar', 11 );


function get_safe_string($string) {
	$clear = preg_replace('/ +/', ' ', preg_replace('/[\\"\n]/', ' ', strip_tags($string)));
	if (strlen($clear) > 300) {
		$clear = substr($clear, 0, 300) . "...";
	}
	return $clear;
}

function community_title($title, $sep, $seplocation) {
	global $lccPost, $lccUser, $lccUserId;

	if ($lccPost) {
		return get_safe_string($lccPost->title) . " " . $sep . " ";
	}
	if ($lccUser && !empty($lccUserId)) {
		return get_safe_string($lccUser->username) . " " . $sep . " ";
	}

    return $title;
}
add_filter('wp_title', 'community_title', 10, 3);

function get_lcc_large_image_url($post) {
	$name = "/lccimages/post_" . $post->objectId . ".png";
	$filePath = WP_CONTENT_DIR . $name;
	$fileUrl = WP_CONTENT_URL . $name;

	if (!file_exists($filePath)) {
		$srcImageFile = file_get_contents($post->image);

		$dstImage = imagecreatetruecolor(LCC_IMAGE_WIDTH, LCC_IMAGE_HEIGHT);
		$srcImage = imagecreatefromstring($srcImageFile);

		$srcSize = getimagesizefromstring($srcImageFile);
		$srcWidth = $srcSize[0];
		$srcHeight = $srcSize[1];

		imagecopyresized($dstImage, $srcImage, 0, 0, 0, 0, LCC_IMAGE_WIDTH, LCC_IMAGE_HEIGHT, $srcWidth, $srcHeight);

		imagepng($dstImage, $filePath);
	}

	return $fileUrl;
}

function community_init() {
	global $lccPostId, $lccUserId, $lccPost, $lccUser, $lccUserPosts;

	if (basename(get_page_template()) == 'community_v2.php') {

		if (!empty($lccPostId)) {

			// Post
			$response = file_get_contents("https://lowresapi.timokloss.com/posts/".$lccPostId);
			$responseData = json_decode($response);

			$lccPost = $responseData->post;
			$lccUser = $responseData->user;

		} else {

			// User or LowRes Coder account
			$id = !empty($lccUserId) ? $lccUserId : "T5VWaLW28x";
			$response = file_get_contents("https://lowresapi.timokloss.com/users/".$id."?limit=50&onlyprograms=1");
			$responseData = json_decode($response);

			$lccUser = $responseData->user;
			$lccUserPosts = $responseData->posts;
		}
		
	}
}
add_action('wp', 'community_init');


remove_action('wp_head', 'rel_canonical');
remove_action('wp_head', 'wp_shortlink_wp_head');

function insert_fb_in_head() {
	global $post, $lccPost, $lccUser;
    if ( !is_singular()) //if it is not a post or a page
        return;

    if ($lccPost) {
    	$title = get_safe_string($lccPost->title);
    	$detail = get_safe_string($lccPost->detail);
		echo '<meta property="og:title" content="' . $title . '"/>';
		echo '<meta property="og:description" content="' . $detail . '"/>';
		echo '<meta property="og:type" content="article"/>';
		echo '<meta property="og:url" content="' . get_permalink() . "?" . $_SERVER['QUERY_STRING'] . '"/>';
		echo '<meta property="og:image" content="' . get_lcc_large_image_url($lccPost) . '"/>';
		echo '<meta property="og:image:width" content="' . LCC_IMAGE_WIDTH . '"/>';
		echo '<meta property="og:image:height" content="' . LCC_IMAGE_HEIGHT . '"/>';
    } else {
		echo '<meta property="og:title" content="' . get_the_title() . '"/>';
		echo '<meta property="og:description" content="Program your own retro games or demos directly on your iPad or iPhone!"/>';
		echo '<meta property="og:type" content="article"/>';
		echo '<meta property="og:url" content="' . get_permalink() . '"/>';
		echo '<meta property="og:image" content="http://lowres.inutilis.com/wordpress/wp-content/uploads/2015/08/shareimage.png"/>';
		echo '<meta property="og:image:width" content="1200"/>';
		echo '<meta property="og:image:height" content="630"/>';
	}
	echo '<meta property="og:site_name" content="LowRes Coder"/>';
    echo "
";
}
add_action('wp_head', 'insert_fb_in_head');

?>