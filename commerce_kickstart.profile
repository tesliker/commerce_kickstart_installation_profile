<?php

/**
 * Implements hook_form_alter().
 *
 * Allows the profile to alter the site configuration form.
 */
function commerce_kickstart_form_install_configure_form_alter(&$form, $form_state) {
  // Set a default name for the dev site.
  $form['site_information']['site_name']['#default_value'] = t('Commerce Kickstart');

  // Set a default country so we can benefit from it on Address Fields.
  $form['server_settings']['site_default_country']['#default_value'] = 'US';
}

/**
 * Implements hook_install_tasks().
 */
function commerce_kickstart_install_tasks() {
  $tasks = array();

  // Add a page allowing the user to indicate they'd like to install demo content.
  $tasks['commerce_kickstart_example_store_form'] = array(
    'display_name' => st('Example store'),
    'type' => 'form',
  );

  return $tasks;
}

/**
 * Task callback: returns the form allowing the user to add example store
 * content on install.
 */
function commerce_kickstart_example_store_form() {
  drupal_set_title(st('Example store content'));

  // Prepare all the options for example content.
  $options = array(
    'products' => st('Products'),
    'product_displays' => st('Product display nodes (if <em>Products</em> is selected)'),
  );

  $form['example_content'] = array(
    '#type' => 'checkboxes',
    '#title' => st('Create example content for the following store components:'),
    '#description' => st('The example content is not comprehensive but illustrates how the basic components work.'),
    '#options' => $options,
    '#default_value' => drupal_map_assoc(array_keys($options)),
  );

  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => st('Create and continue'),
    '#weight' => 15,
  );

  return $form;
}

/**
 * Submit callback: creates the requested example content.
 */
function commerce_kickstart_example_store_form_submit(&$form, &$form_state) {
  $example_content = $form_state['values']['example_content'];
  $created_products = array();
  $created_nodes = array();

  // First create products if specified.
  if (!empty($example_content['products'])) {
    $product_names = array(
      '01' => st('Product One'),
      '02' => st('Product Two'),
      '03' => st('Product Three')
    );

    foreach ($product_names as $sku => $title) {
      // Create the new product.
      $product = commerce_product_new('product');
      $product->sku = 'PROD-' . $sku;
      $product->title = $title;
      $product->language = LANGUAGE_NONE;
      $product->uid = 1;

      // Set a default price.
      $product->commerce_price[LANGUAGE_NONE][0]['amount'] = $sku * 1000;
      $product->commerce_price[LANGUAGE_NONE][0]['currency_code'] = 'USD';

      // Save it and retain a copy.
      commerce_product_save($product);
      $created_products[] = $product;

      // Create a node display for the product if specified.
      if (!empty($example_content['product_displays'])) {
        // Create the new node.
        $node = (object) array('type' => 'product_display');
        node_object_prepare($node);
        $node->title = $product->title;
        $node->uid = 1;

        // Reference the product we just made.
        $node->field_product[LANGUAGE_NONE][]['product_id'] = $product->product_id;

        // Make sure we set the default language
        $node->language = LANGUAGE_NONE;

        // Save it and retain a copy.
        node_save($node);
        $created_nodes[] = $node;
      }
    }
	//adding tommy's nodes from callback
  module_enable(array('bsc_install'), TRUE);
	commerce_kickstart_add_nodes();
	commerce_kickstart_delete_blocks('login');
	commerce_kickstart_delete_blocks('powered-by');
  commerce_kickstart_edit_block_title('superfish', '<none>');
	new_fp_link('links', 'FP Link 1', '/images/slide1.jpg', '/node/1');
  new_fp_link('links', 'FP Link 2', '/images/slide2.jpg', '/node/2');
	new_fp_link('links', 'FP Link 3', '/images/slide1.jpg', '/node/1');
	new_fp_link('links', 'FP Link 4', '/images/slide2.jpg', '/node/2');
  new_article('article', 'test article 1', '/images/slide1.jpg');
  new_article('article', 'test article 2', '/images/slide2.jpg');
  }
}

/**
 * Creates a Catalog taxonomy vocabulary and adds a term reference field for it
 * to the default product display node type.
 *
 * @todo This function is currently unused but should be added in as an option
 * for example content creation.
 */
function _commerce_kickstart_create_example_catalog() {
  // Create a default Catalog vocabulary for the Product display node type.
  $description = st('Describes a hierarchy for the product catalog.');
  $vocabulary = (object) array(
    'name' => st('Catalog'),
    'description' => $description,
    'machine_name' => 'catalog',
    'help' => '',
  );
  taxonomy_vocabulary_save($vocabulary);

  $field = array(
    'field_name' => 'taxonomy_' . $vocabulary->machine_name,
    'type' => 'taxonomy_term_reference',
    'cardinality' => 1,
    'settings' => array(
      'allowed_values' => array(
        array(
          'vocabulary' => $vocabulary->machine_name,
          'parent' => 0,
        ),
      ),
    ),
  );
  field_create_field($field);

  $instance = array(
    'field_name' => 'taxonomy_' . $vocabulary->machine_name,
    'entity_type' => 'node',
    'label' => st('Catalog category'),
    'bundle' => 'product_display',
    'description' => '',
    'widget' => array(
      'type' => 'options_select',
    ),
  );
  field_create_instance($instance);
}

/**
 * Creates an image field on the specified entity bundle.
 */
function _commerce_kickstart_create_product_image_field($entity_type, $bundle) {
  // Add a default image field to the specified product type.
  $instance = array(
    'field_name' => 'field_image',
    'entity_type' => $entity_type,
    'label' => st('Image'),
    'bundle' => $bundle,
    'description' => st('Upload an image for this product.'),
    'required' => FALSE,

    'settings' => array(
      'file_directory' => 'field/image',
      'file_extensions' => 'png gif jpg jpeg',
      'max_filesize' => '',
      'max_resolution' => '',
      'min_resolution' => '',
      'alt_field' => TRUE,
      'title_field' => '',
    ),

    'widget' => array(
      'type' => 'image_image',
      'settings' => array(
        'progress_indicator' => 'throbber',
        'preview_image_style' => 'thumbnail',
      ),
      'weight' => -1,
    ),

    'display' => array(
      'default' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => 'file'),
        'weight' => -1,
      ),
      'full' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => 'file'),
        'weight' => -1,
      ),
      'line_item' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'thumbnail', 'image_link' => ''),
        'weight' => -1,
      ),
      'node_full' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => 'file'),
        'weight' => -1,
      ),
      'node_teaser' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'thumbnail', 'image_link' => 'content'),
        'weight' => -1,
      ),
      'node_rss' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => ''),
        'weight' => -1,
      ),
    ),
  );
  field_create_instance($instance);
}

/**
 * Creates a product reference field on the specified entity bundle.
 */
function _commerce_kickstart_create_product_reference($entity_type, $bundle, $field_name = 'field_product') {
  // Add a product reference field to the Product display node type.
  $field = array(
    'field_name' => $field_name,
    'type' => 'commerce_product_reference',
    'cardinality' => FIELD_CARDINALITY_UNLIMITED,
    'translatable' => FALSE,
  );
  field_create_field($field);

  $instance = array(
    'field_name' => $field_name,
    'entity_type' => $entity_type,
    'label' => st('Product'),
    'bundle' => $bundle,
    'description' => st('Choose the product(s) to display for sale on this node by SKU. Enter multiple SKUs using a comma separated list.'),
    'required' => TRUE,

    'widget' => array(
      'type' => 'commerce_product_reference_autocomplete',
    ),

    'display' => array(
      'default' => array(
        'label' => 'hidden',
        'type' => 'commerce_cart_add_to_cart_form',
      ),
      'full' => array(
        'label' => 'hidden',
        'type' => 'commerce_cart_add_to_cart_form',
      ),
      'teaser' => array(
        'label' => 'hidden',
        'type' => 'commerce_cart_add_to_cart_form',
      ),
    ),
  );
  field_create_instance($instance);
}

/**
 * Implements hook_update_projects_alter().
 */
function commerce_kickstart_update_projects_alter(&$projects) {
  // Enable update status for the Commerce Kickstart profile.
  $modules = system_rebuild_module_data();
  // The module object is shared in the request, so we need to clone it here.
  $kickstart = clone $modules['commerce_kickstart'];
  $kickstart->info['hidden'] = FALSE;
  _update_process_info_list($projects, array('commerce_kickstart' => $kickstart), 'module', TRUE);
}

/**
 * Implements hook_update_status_alter().
 *
 * Disable reporting of modules that are in the distribution, but only
 * if they have not been updated manually. In addition, we only hide security
 * issues if the distribution itself has not been updated.
 */
function commerce_kickstart_update_status_alter(&$projects) {
  $distribution_secure = !in_array($projects['commerce_kickstart']['status'], array(UPDATE_NOT_SECURE, UPDATE_REVOKED, UPDATE_NOT_SUPPORTED));
  $make_filepath = drupal_get_path('module', 'commerce_kickstart') . '/drupal-org.make';
  if (!file_exists($make_filepath)) {
    return;
  }
  $make_info = drupal_parse_info_file($make_filepath);
  foreach ($projects as $project_name => $project_info) {
    if (!isset($project_info['info']['version']) || !isset($make_info['projects'][$project_name])) {
      // Don't hide a project that is not shipped with the distribution.
      continue;
    }
    if ($distribution_secure && in_array($project_info['status'], array(UPDATE_NOT_SECURE, UPDATE_REVOKED, UPDATE_NOT_SUPPORTED))) {
      // Don't hide a project that is in a security state if the distribution
      // is not in a security state.
      continue;
    }
    $make_project_version = is_array($make_info['projects'][$project_name]) ? $make_info['projects'][$project_name]['version'] : $make_info['projects'][$project_name];

    // Current version matches the version we shipped, remove it from the list.
    if (DRUPAL_CORE_COMPATIBILITY . '-' . $make_project_version == $project_info['info']['version']) {
      $projects['commerce_kickstart']['includes'][$project_info['name']] = $project_info['info']['name'];
      unset($projects[$project_name]);
    }
  }
}

function commerce_kickstart_delete_blocks($delta) {
	$remove_block = db_update('block') // Table name no longer needs {}
	  ->fields(array(
		'region' => '-1',
	  ))
	  ->condition('delta', $delta, '=')
	  ->execute();
	return $remove_block; 
}

function commerce_kickstart_edit_block_title($module, $title) {
	$block = db_update('block') // Table name no longer needs {}
	  ->fields(array(
		'title' => $title,
	  ))
    ->condition('module', $module, '=')
	  ->execute();
	return $block; 
}

function commerce_kickstart_add_nodes() {
   // Create a node object, and add node properties.
  $newSlide = (object) array('type' => 'slideshow_image'); //banner is the content type, with title & image fields
  node_object_prepare($newSlide);
  $newSlide->type = 'slideshow_image';
  $newSlide->title = 'slide-1';
  $newSlide->uid = 1;
  $newSlide->comment = 0;
  $newSlide->promote = 0;
  $newSlide->moderate = 0;
  $newSlide->sticky = 0;
  $newSlide->language = 'und';
//I am storing images in /images folder of my install profile
  $file_path = drupal_get_path('profile', 'commerce_kickstart') . '/images/slide1.jpg';
//Preparing file object
    $file = (object)array(
      "uid" => 1,
      "uri" => $file_path,
      "filemime" => file_get_mimetype($file_path),
      "status" => 1
    );
//copying files from profile/images folder to public folder. This works, as the files are copied to the files folder & also entries are created in database tables
    $file = file_copy($file, 'public://', FILE_EXISTS_REPLACE);
    $newSlide->field_image['und'][0] = (array)$file;
	$newSlide->field_slideshow_type['und'][0]['value'] = 'Front Page';
  $newSlide->field_overlay_position['und'][0]['value'] = 'top-left';
	$newSlide->field_weight['und'][0]['value'] = '1';
    node_submit($newSlide);
    node_save($newSlide);

   // Create a node object, and add node properties.
  $newSlide2 = (object) array('type' => 'slideshow_image'); //banner is the content type, with title & image fields
  node_object_prepare($newSlide2);
  $newSlide2->type = 'slideshow_image';
  $newSlide2->title = 'slide-2';
  $newSlide2->uid = 1;
  $newSlide2->comment = 0;
  $newSlide2->promote = 0;
  $newSlide2->moderate = 0;
  $newSlide2->sticky = 0;
  $newSlide2->language = 'und';
//I am storing images in /images folder of my install profile
  $file_path = drupal_get_path('profile', 'commerce_kickstart') . '/images/slide2.jpg';
//Preparing file object
    $file = (object)array(
      "uid" => 1,
      "uri" => $file_path,
      "filemime" => file_get_mimetype($file_path),
      "status" => 1
    );
//copying files from profile/images folder to public folder. This works, as the files are copied to the files folder & also entries are created in database tables
    $file = file_copy($file, 'public://', FILE_EXISTS_REPLACE);
    $newSlide2->field_image['und'][0] = (array)$file;
	$newSlide2->field_slideshow_type['und'][0]['value'] = 'Front Page';
  $newSlide2->field_overlay_position['und'][0]['value'] = 'bottom-right';
	$newSlide2->field_weight['und'][0]['value'] = '2';
// The above line tries to attach $file object to the file field, and THIS NOT WORKING from .install file
// I also tried this
// $newSlide2->field_home_banner_image[LANGUAGE_NONE][0] = (array)$file;
// and this
// $newSlide2->field_home_banner_image['und'][] = (array)$file;
// Save the node.
    node_submit($newSlide2);
    node_save($newSlide2);


$newWebform = new stdClass();
$newWebform->type = 'webform';
node_object_prepare($newWebform);
$newWebform->title = 'Contact Us';
$newWebform->language = 'en';
$newWebform->body[LANGUAGE_NONE][0]['value']   = '';
$newWebform->body[LANGUAGE_NONE][0]['format']  = 'full_html';
$newWebform->uid = 1;
$newWebform->promote = 0;
$newWebform->comment = 0;
// Create the webform components.
$components = array(
array(
  'name' => 'First name',
  'form_key' => 'first_name',
  'type' => 'textfield',
  'mandatory' => 1,
  'weight' => 1,
  'pid' => 0,
  'extra' => array(
    'title_display' => 'inline',
    'private' => 0,
  ),
),
array(
  'name' => 'Last name',
  'form_key' => 'last_name',
  'type' => 'textfield',
  'mandatory' => 1,
  'weight' => 2,
  'pid' => 0,
  'extra' => array(
    'title_display' => 'inline',
    'private' => 0,
  ),
),
array(
  'name' => 'Email',
  'form_key' => 'email',
  'type' => 'email',
  'mandatory' => 1,
  'weight' => 3,
  'pid' => 0,
  'extra' => array(
    'title_display' => 'inline',
    'private' => 0,
  ),
),
array(
  'name' => 'Message',
  'form_key' => 'message',
  'type' => 'textarea',
  'mandatory' => 1,
  'weight' => 4,
  'pid' => 0,
  'extra' => array(
    'title_display' => 'inline',
    'private' => 0,
    ),
  ),
);
// Setup notification email.
$emails = array(
  array(
    'email' => 'tsliker@sliker.com, tesliker@sliker.com',
    'subject' => 'default',
    'from_name' => 'default',
    'from_address' => 'default',
    'template' => 'default',
    'excluded_components' => array(),
  ),
);
// Attach the webform to the node.
$newWebform->webform = array(
  'confirmation' => '',
  'confirmation_format' => NULL,
  'redirect_url' => '<confirmation>',
  'status' => '1',
  'block' => '0',
  'teaser' => '0',
  'allow_draft' => '0',
  'auto_save' => '0',
  'submit_notice' => '1',
  'submit_text' => '',
  'submit_limit' => '-1', // User can submit more than once.
  'submit_interval' => '-1',
  'total_submit_limit' => '-1',
  'total_submit_interval' => '-1',
  'record_exists' => TRUE,
  'roles' => array(
    0 => '1',// Anonymous user can submit this webform.
    1 => '2',
    3 => '3',
  ),
  'emails' => $emails,
  'components' => $components,
);
// Save the node.
node_save($newWebform);

//set up the user fields
$userTesliker = array(
'name' => 'tesliker',
'mail' => 'tesliker@sliker.com',
'pass' => 'outkast',
'status' => 1,
'init' => 'email address',
'roles' => array(
  DRUPAL_AUTHENTICATED_RID => 'authenticated user', '3' => 'administrator',
),
);
//the first parameter is left blank so a new user is created
user_save('', $userTesliker);

//set up the user fields
$userTsliker = array(
'name' => 'tsliker',
'mail' => 'tsliker@sliker.com',
'pass' => 'newroper',
'status' => 1,
'init' => 'email address',
'roles' => array(
  DRUPAL_AUTHENTICATED_RID => 'authenticated user', '3' => 'administrator',
),
);
//the first parameter is left blank so a new user is created
user_save('', $userTsliker);

//set up the user fields
$userSlikerm = array(
'name' => 'slikerm',
'mail' => 'marj@sliker.com',
'pass' => 'carolinaqt09',
'status' => 1,
'init' => 'email address',
'roles' => array(
  DRUPAL_AUTHENTICATED_RID => 'authenticated user', '3' => 'administrator',
),
);
//the first parameter is left blank so a new user is created
user_save('', $userSlikerm);

// creating about us page
  $newPage = (object) array('type' => 'page');
  node_object_prepare($newPage);
  $newPage->type = 'page';
  $newPage->title = 'About Us';
  $newPage->uid = 1;
  $newPage->comment = 0;
  $newPage->promote = 0;
  $newPage->moderate = 0;
  $newPage->sticky = 0;
  $newPage->language = 'und';
	$newPage->body['und'][0]['value'] = '<p>This is the about us page</p>';
	$newPage->body['und'][0]['format'] = 'full_html';
	$newPage->body['und'][0]['safe_value'] = '<p>This is the about us page</p>';
    node_submit($newPage);
    node_save($newPage);





}

function new_fp_link($type, $title, $imgpath, $link) {
   // Create a node object, and add node properties.
  $newNode = (object) array('type' => $type); //banner is the content type, with title & image fields
  node_object_prepare($newNode);
  $newNode->type = $type;
  $newNode->title = $title;
  $newNode->uid = 1;
  $newNode->comment = 0;
  $newNode->promote = 0;
  $newNode->moderate = 0;
  $newNode->sticky = 0;
  $newNode->language = 'und';
//I am storing images in /images folder of my install profile
  $file_path = drupal_get_path('profile', 'commerce_kickstart') . $imgpath;
//Preparing file object
    $file = (object)array(
      "uid" => 1,
      "uri" => $file_path,
      "filemime" => file_get_mimetype($file_path),
      "status" => 1
    );
    $file = file_copy($file, 'public://', FILE_EXISTS_REPLACE);
    $newNode->field_image['und'][0] = (array)$file;
	$newNode->field_link['und'][0]['url'] = $link;
	$newNode->field_link['und'][0]['title'] = 'Link1';
	$newNode->field_link['und'][0]['display_url'] = $link;
	$newNode->field_link['und'][0]['html'] = TRUE;
	$newNode->body['und'][0]['value'] = '<p>This is a test fp_link</p>';
	$newNode->body['und'][0]['format'] = 'full_html';
	$newNode->body['und'][0]['safe_value'] = '<p>This is a test fp_link</p>';
    node_submit($newNode);
    node_save($newNode);
}

function new_article($type, $title, $imgpath) {
   // Create a node object, and add node properties.
  $newNode = (object) array('type' => $type); //banner is the content type, with title & image fields
  node_object_prepare($newNode);
  $newNode->type = $type;
  $newNode->title = $title;
  $newNode->uid = 1;
  $newNode->comment = 0;
  $newNode->promote = 0;
  $newNode->moderate = 0;
  $newNode->sticky = 0;
  $newNode->language = 'und';
//I am storing images in /images folder of my install profile
  $file_path = drupal_get_path('profile', 'commerce_kickstart') . $imgpath;
//Preparing file object
    $file = (object)array(
      "uid" => 1,
      "uri" => $file_path,
      "filemime" => file_get_mimetype($file_path),
      "status" => 1
    );
    $file = file_copy($file, 'public://', FILE_EXISTS_REPLACE);
    $newNode->field_image['und'][0] = (array)$file;
	$newNode->body['und'][0]['value'] = '<p>This is a test article</p>';
	$newNode->body['und'][0]['format'] = 'full_html';
	$newNode->body['und'][0]['safe_value'] = '<p>This is a test article</p>';
    node_submit($newNode);
    node_save($newNode);
}

function commerce_kickstart_block_save($delta) {
  
}
