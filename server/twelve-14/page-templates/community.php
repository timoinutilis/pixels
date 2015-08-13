<?php
/**
 * Template Name: Community Page
 *
 * @package WordPress
 * @subpackage Twelve_Fourteen
 * @since Twelve_Fourteen 1.1
 */

require dirname(__FILE__) . '/../autoload.php';
 
use Parse\ParseClient;
use Parse\ParseQuery;
use Parse\ParseException;
use Parse\ParseUser;

$lccPostId = $_GET["lcc_post_id"];
$lccUserId = $_GET["lcc_user_id"];

$pageUrl = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

ParseClient::initialize('JjXUGeQFrN79s4TcIunronsM13ehsBy0Pa1FLIUA', 'YlUL5qFSyRFVS0rFLdIHUQjNuTzHi294XDy7G9Em', 'g8mqpMyqSxN78OUfwmT7gwPLqOIQ4VqG4N0YWAg3');

$lccPost = NULL;
$lccUser = NULL;

$title = "";

try {
	if (!empty($lccPostId)) {

		$query = new ParseQuery("Post");
		$query->includeKey("user");
		$lccPost = $query->get($lccPostId);
		$lccUser = $lccPost->get("user");

		$title = $lccPost->get("title");

	} else {

		if (!empty($lccUserId)) {
			// User
			$query = ParseUser::query();
			$lccUser = $query->get($lccUserId);
			$title = $lccUser->get("username");
		} else {
			// "LowRes Coder" account
			$query = ParseUser::query();
			$lccUser = $query->get("T5VWaLW28x");
			$title = "Featured Programs";
		}

		$query = new ParseQuery("Post");
		$query->equalTo("user", $lccUser);
		$query->notEqualTo("type", 2);
		$query->includeKey("sharedPost");
		$query->descending("createdAt");
		$lccUserPosts = $query->find();

	}

} catch (ParseException $ex) {
	$title = "Not found";
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
			$postImageUrl = $lccPost->get("image")->getURL();
			$programFile = $lccPost->get("programFile");
			if ($programFile) {
				$sourceCodeUrl = $programFile->getURL();
			} else {
				$sourceCodeUrl = "http://lowres.inutilis.com/wordpress/wp-content/themes/twelve-14/sourcecode.php?id=" . $lccPost->get("program")->getObjectId();
			}
		?>

		<div class="lcc-images"><img src="<?php echo $postImageUrl; ?>"></div>
		<p class="lcc-author">By <a href="<?php echo $pageUrl . "?lcc_user_id=" . $lccUser->getObjectId(); ?>"><?php echo $lccUser->get("username"); ?></a></p>
		<p class="lcc-description"><?php echo wptexturize(nl2br($lccPost->get("detail"))); ?></p>

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
 					<a href="<?php echo $pageUrl . "?lcc_post_id=" . $userPost->getObjectId(); ?>">
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
