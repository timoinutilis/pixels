<?php
/**
 * Template Name: Community Page
 *
 * @package WordPress
 * @subpackage Twelve_Fourteen
 * @since Twelve_Fourteen 1.1
 */

$pageUrl = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

$title = "";

if (!empty($lccPostId)) {
	if ($lccPost) {
		$title = $lccPost->get("title");
	} else {
		$title = "Program not found";
	}
} else {
	if (!empty($lccUserId)) {
		// User
		if ($lccUser) {
			$title = $lccUser->get("username");
		} else {
			$title = "User not found";
		}
	} else {
		// "LowRes Coder" account
		$title = "Featured Programs";
	}
}

get_header(); ?>

<div id="main-content" class="main-content">

	<div id="primary" class="content-area">
		<div id="content" class="site-content" role="main">

<article id="post-<?php the_ID(); ?>" <?php post_class(); ?>>
	<?php
		// Page thumbnail and title.
		twentyfourteen_post_thumbnail();
	?>

	<header class="entry-header"><h1 class="entry-title"><?php echo wptexturize($title); ?></h1></header><!-- .entry-header -->

	<div class="entry-content">
		<?php if ($lccPost) { ?>

		<?php
			$postImageUrl = get_lcc_large_image_url($lccPost);
			$programFile = $lccPost->get("programFile");
			if ($programFile) {
				$sourceCodeUrl = $programFile->getURL();
			} else {
				$sourceCodeUrl = "http://lowres.inutilis.com/wordpress/wp-content/themes/twelve-14/sourcecode.php?id=" . $lccPost->get("program")->getObjectId();
			}
		?>

		<p class="lcc-author"><strong>By <a href="<?php echo $pageUrl . "?lccuser=" . $lccUser->getObjectId(); ?>"><?php echo $lccUser->get("username"); ?></a></strong></p>
		<div class="lcc-images"><img src="<?php echo $postImageUrl; ?>"></div>
		<p class="lcc-description"><?php echo wptexturize(nl2br($lccPost->get("detail"))); ?></p>
		<p>
			<strong><a href="https://itunes.apple.com/us/app/lowres-coder/id962117496?mt=8&uo=4">Get LowRes Coder</a> to use this program.</strong>
			<form method="GET" action="lowrescoder://">
				<input type="hidden" name="lccpost" value="<?php echo $lccPost->getObjectId(); ?>">
				<input type="submit" value="Open in App">
				(Button requires LowRes Coder 3.2)
			</form>
		</p>

		<iframe class="lcc-sourcecode" src="<?php echo $sourceCodeUrl; ?>" width="100%" height="400"></iframe>

		<?php } else if ($lccUser) {

		if (!empty($lccUserId)) { ?>
		<p class="lcc-about"><?php echo wptexturize(nl2br($lccUser->get("about"))); ?></p>
		<?php } ?>

		<div class="lcc-posts">

		<?php
			for ($i = 0; $i < count($lccUserPosts); $i++) {
 				$userPost = $lccUserPosts[$i];
 				if ($userPost->get("sharedPost")) {
 					$userPost = $userPost->get("sharedPost");
 				}
 		?>

 				<div class="lcc-post">
 					<a href="<?php echo $pageUrl . "?lccpost=" . $userPost->getObjectId(); ?>">
 						<img src="<?php echo $userPost->get("image")->getURL(); ?>">
 						<p><?php echo $userPost->get("title"); ?></p>
 					</a>
 				</div>

 		<?php
			}
		?>

		</div>

		<?php } ?>

	</div><!-- .entry-content -->
</article><!-- #post-## -->

		</div><!-- #content -->
	</div><!-- #primary -->
	<?php get_sidebar( 'content' ); ?>
</div><!-- #main-content -->

<?php
get_sidebar();
get_footer();
